class FeedbackController < ApplicationController

  skip_before_action :verify_authenticity_token, :only => :create
  skip_before_action :authenticate_user!, :only => :create

  def create
    vals = []
    params.each do |key,val|
      matches = key.match(/entry\.([0-9]+)\.single/)
      if matches
        vals[matches[1].to_i] = val
      end
    end
    vals.unshift(Time.now.to_s)
    Feedback.import_row(vals,{})
    Feedback.auto_handle
    head :ok
  end

  def analyse
    render plain: Feedback.analyse
  end

  def search
    if params[:feedbacks]
      params[:email_attempts].each do |id,ea|
        email_attempt = EmailAttempt.find(id)
        if ea['status'] and email_attempt.status != ea['status']
          email_attempt.status = ea['status']
        end
        if ea['new_status'] and ! ea['new_status'].empty?
          email_attempt.status = ea['new_status']
        end
        if ea['failure_status'] and email_attempt.failure_status != ea['failure_status']
          email_attempt.failure_status = ea['failure_status']
        end
        if ea['new_failure_status'] and ! ea['new_failure_status'].empty?
          email_attempt.failure_status = ea['new_failure_status']
        end
        email_attempt.save!
      end

      @active_feedbacks = []
      params[:feedbacks].each do |id,p|
        feedback = Feedback.find(id)
        if p['email_address'] and feedback.email_address != p['email_address']
          feedback.email_address = p['email_address']
        end
        if p['email_status'] and feedback.email_status != p['email_status']
          feedback.email_status = p['email_status'] == '' ? nil : p['email_status']
        end
        feedback.save!
        @active_feedbacks << feedback
      end
    elsif params[:email_address] and ! params[:email_address].empty?
      email_address = "%#{params[:email_address].strip}%"
      @active_feedbacks = Feedback.where(["email_address LIKE ? OR original_email LIKE ?", email_address, email_address])
    elsif params[:status] and ! params[:status].empty?
      @active_feedbacks = Feedback.where({ :status => params[:status] })
    elsif params[:email_status] and ! params[:email_status].empty?
      @active_feedbacks = Feedback.where({ :email_status => params[:email_status] })
    elsif params[:failure_status] and ! params[:failure_status].empty?
      if params[:failure_status] == "nil" or params[:failure_status] == "null"
        @active_feedbacks = Feedback.where(["email_attempts.failure_status IS NULL and email_attempts.status = 'failed'"]).joins(:email_attempts).group('feedbacks.id')
      else
        @active_feedbacks = Feedback.where(["id IN (SELECT feedback_id FROM email_attempts WHERE failure_status = ?)",params[:failure_status]])
      end
    end
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
      @active_feedbacks = session[:last_list_page].map { |id| Feedback.includes(:feedback_values).find(id) }
    else
      @active_feedbacks = []
      @last_feedback_id = nil
      start_feedback = session[:last_list_active_feedback]
      @count_left = Feedback.where("status = ''").count
      if start_feedback
        feedbacks = Feedback.includes(:feedback_values).where([ "status = '' AND id >= ?", start_feedback ]).order("id ASC").all
      end
      if feedbacks.nil?
        feedbacks = Feedback.includes(:feedback_values).where("status = ''").order("id ASC").all
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
        @active_feedback = Feedback.includes(:feedback_values).find(params[:id])
      end
      if @active_feedback.nil?
        if start_feedback
          @active_feedback = Feedback.includes(:feedback_values).where([ "status = '' AND id >= ?", start_feedback ]).order("id ASC").first
        end
        if @active_feedback.nil?
          @active_feedback = Feedback.includes(:feedback_values).where([ "status = ''"]).order("id ASC").first
        end
        if @active_feedback
          session[:last_active_feedback] = @active_feedback.id
        end
      end
      @count_left = Feedback.where("status = ''").count
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
    dupes = Feedback.includes(:feedback_values).where(conditions)
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
        @email_content = FeedbackMailer.content_for_status(params[:status], @active_feedback)
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
