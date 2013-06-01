class FeedbackController < ApplicationController

  def analyse
    render :text => Feedback.analyse
  end

  def list
    if params[:reset_feedback] == "yes"
      session[:last_list_active_feedback] = nil
      redirect_to :action => :list
    elsif params[:status] and request.method == "POST"
      params[:status].each do |feedback_id,status|
        f = Feedback.find(feedback_id)
        if not status.empty? and status != f.status
          f.status = status
          f.save!
        end
      end
      last_page = params[:status].keys.map { |a| a.to_i }
      session[:last_list_page] = last_page
      if params[:last_feedback_id]
        session[:last_list_active_feedback] = params[:last_feedback_id].to_i
      end
      redirect_to :action => :list
    elsif params[:show] == "lastpage" and session[:last_list_page]
      @active_feedbacks = session[:last_list_page].map { |id| Feedback.find(id, :include => :feedback_values) }
    else
      @active_feedbacks = []
      @last_feedback_id = nil
      start_feedback = session[:last_list_active_feedback]
      @count_left = Feedback.count(:conditions => "status = ''")
      if start_feedback
        feedbacks = Feedback.find(:all, :conditions => [ "status = '' AND id >= ?", start_feedback ], :order => "id ASC", :include => :feedback_values)
      end
      if feedbacks.nil?
        feedbacks = Feedback.find(:all, :conditions => "status = ''", :order => "id ASC", :include => :feedback_values)
      end
      feedbacks.each do |f|
        if @active_feedbacks.index(f)
          next
        end

        status = f.status
        if status.nil? or status.strip.empty?
          @active_feedbacks << f
          @last_feedback_id = f.id
          dupes = generate_other_feedback(f)
          dupes.each do |dupe|
            d = dupe[:feedback]
            if @active_feedbacks.index(d).nil? and dupe[:status].empty?
              @active_feedbacks << d
            end
          end
          break if @active_feedbacks.length >= 20
        end
      end
    end
  end

  def index
    if params[:reset_feedback] == "yes"
      session[:last_active_feedback] = nil
      redirect_to :action => :index
    elsif params[:skip] == "yes"
      if session[:last_active_feedback]
        session[:last_active_feedback] += 1
      end
      redirect_to :action => :index
    else
      start_feedback= session[:last_active_feedback]
      if params[:id].to_i > 0
        @active_feedback = Feedback.find(params[:id], :include => :feedback_values)
      end
      if @active_feedback.nil?
        if start_feedback
          @active_feedback = Feedback.find(:first, :conditions => [ "status = '' AND id >= ?", start_feedback ], :order => "id ASC", :include => :feedback_values)
        end
        if @active_feedback.nil?
          @active_feedback = Feedback.find(:first, :conditions => "status = ''", :order => "id ASC", :include => :feedback_values)
        end
        if @active_feedback
          session[:last_active_feedback] = @active_feedback.id
        end
      end
      @other_feedback = []
      @other_feedback_index = 0
      if @active_feedback
        @other_feedback = generate_other_feedback(@active_feedback)
        @other_feedback.each_index do |i|
          dupe = @other_feedback[i]
          if dupe[:id] == @active_feedback.id
            @other_feedback_index = i
            break
          end
        end
      end
    end
  end

  def generate_other_feedback(active_feedback)
    conditions = [ "device_udid = ?", active_feedback.device_udid ]
    if not active_feedback.original_email.empty?
      conditions[0] += " OR original_email = ?"
      conditions << active_feedback.original_email
    end
    dupes = Feedback.find(:all, :conditions => conditions, :include => :feedback_values )
    dupes.map do |d|
      { id: d.id,
        status: d.status,
        feedback: d,
        email_sent: (d.email_status ? "!" : " "),
        email_failed: (d.email_status == "failed")
        }
    end
  end

  def reload
    # Cache the output, we don't need it here
    flash[:notice] = Feedback.import_spreadsheet(false)

    redirect_to action: params[:source] ? params[:source] : "index"
  end

  def feedback_link(f)
    "<a href=\"#{url_for action: "index", id: f.id}\">#{f.id}</a>"
  end

  def updateemail
    if params[:id] and params[:email]
      f = Feedback.find(params[:id])
      f.email_address = params[:email]
      f.save!
      flash[:notice] = "Email updated for feedback #{feedback_link(f)}".html_safe
    end
    redirect_to action: "index", id: params[:id]
  end

  def status
    @active_feedback = Feedback.find(params[:id])
    if params[:email_content] and params[:button] == "Send"
      ea = EmailAttempt.new
      ea.feedback = @active_feedback
      ea.email_address = params[:email_recipient]
      ea.email_content = params[:email_content]
      begin
        FeedbackMailer.feedback_email(params[:email_recipient],params[:email_content]).deliver
        ea.status = 'success'
        flash[:notice] = "Email sent for row #{feedback_link(@active_feedback)} and status saved.".html_safe
      rescue Exception => e
        p "Email send failed: #{e.inspect}"
        ea.status = 'failed'
        ea.failure_status = 'unknown'
        flash[:notice] = "Email sending failed for row #{feedback_link(@active_feedback)} and status saved.".html_safe
      end
      ea.save!
      @active_feedback.email_status = ea.status
      # DROP DOWN AND SAVE STATUS
    elsif params[:email] == "Edit" or GDRIVE_CRM_STATUS_REQUIRES_EDIT.index(params[:status])
      # Show the email and allow editing.
      if params[:email_content]
        @email_content = params[:email_content]
      else
        @email_content = FeedbackMailer.content_for_status(params[:status])
      end
      if params[:email_recipient]
        @email_recipient = params[:email_recipient]
      else
        @email_recipient = @active_feedback.email_address
      end
      @other_feedback = []

      # GO NO FURTHER
      return
    end

    @active_feedback.status = params[:status]
    @active_feedback.save!
    flash[:notice] = "Status saved for row #{feedback_link(@active_feedback)}".html_safe if flash[:notice].nil?
    redirect_to action: "index"
  end
end
