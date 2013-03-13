class FeedbackController < ApplicationController

  def list
    @worksheet = GDRIVE_CRM_WORKSHEET
    if params[:reset_row] == "yes"
      session[:last_list_active_row] = nil
      redirect_to :action => :list
    elsif params[:status] and request.method == "POST"
      params[:status].each do |row,status|
        if not status.empty? and status != @worksheet[row.to_i,GDRIVE_CRM_STATUS_COL]
          @worksheet[row.to_i,GDRIVE_CRM_STATUS_COL] = status
        end
      end
      @worksheet.save
      last_page = params[:status].keys.map { |a| a.to_i }
      session[:last_list_page] = last_page
      if params[:last_row]
        session[:last_list_active_row] = params[:last_row].to_i
      end
      redirect_to :action => :list
    elsif params[:show] == "lastpage" and session[:last_list_page]
      @dupe_hash = generate_dupe_hash
      @active_rows = session[:last_list_page]
    elsif @worksheet
      @dupe_hash = generate_dupe_hash
      @active_rows = []
      @last_row = nil
      start_row = session[:last_list_active_row]
      start_row = GDRIVE_CRM_HEADER_ROW ? 2 : 1 if start_row.nil? or start_row < 1
      for row in start_row..@worksheet.num_rows
        if @active_rows.index(row)
          next
        end

        status = @worksheet[row, GDRIVE_CRM_STATUS_COL]
        if status.nil? or status.strip.empty?
          @active_rows << row
          @last_row = row
          id_key = generate_id_key(row)
          dupes = @dupe_hash[id_key]
          dupes.each do |dupe|
            if @active_rows.index(dupe[:row]).nil? and dupe[:status].empty?
              @active_rows << dupe[:row]
            end
          end
          break if @active_rows.length >= 20
        end
      end
    end
  end

  def index
    @worksheet = GDRIVE_CRM_WORKSHEET

    if params[:reset_row] == "yes"
      session[:last_active_row] = nil
      redirect_to :action => :index
    elsif params[:skip] == "yes"
      if session[:last_active_row]
        session[:last_active_row] += 1
      end
      redirect_to :action => :index
    elsif @worksheet
      start_row = session[:last_active_row]
      start_row = GDRIVE_CRM_HEADER_ROW ? 2 : 1 if start_row.nil?
      if params[:row].to_i > 0 and params[:row].to_i <= @worksheet.num_rows
        @active_row = params[:row].to_i
      else
        for row in start_row..@worksheet.num_rows

          status = @worksheet[row, GDRIVE_CRM_STATUS_COL]
          if status.nil? or status.strip.empty?
            @active_row = row
            session[:last_active_row] = @active_row
            break
          end
        end
      end
      @other_feedback = []
      @other_feedback_index = 0
      if @active_row
        @other_feedback = generate_other_feedback(@active_row)
        @other_feedback.each_index do |i|
          dupe = @other_feedback[i]
          if dupe[:row] == @active_row
            @other_feedback_index = i
            break
          end
        end
      end
    end
  end

  def generate_other_feedback(active_row)
    this_ids = GDRIVE_CRM_IDENTIFYING_COLS.map { |col| GDRIVE_CRM_WORKSHEET[active_row,col] }
    this_ids.delete_if { |val| val.nil? || val == "" }
    generate_dupe_hash()[this_ids.join(',')]
  end

  def generate_id_key(row)
      ids = GDRIVE_CRM_IDENTIFYING_COLS.map { |col| GDRIVE_CRM_WORKSHEET[row,col] }
      ids.delete_if { |val| val.nil? || val == "" }
      ids.join(',')
  end

  def generate_dupe_hash()
    dupe_hash = {}
    start_row = GDRIVE_CRM_HEADER_ROW ? 2 : 1
    for row in start_row..GDRIVE_CRM_WORKSHEET.num_rows
      id_key = generate_id_key(row)

      dupe = { row: row, status: GDRIVE_CRM_WORKSHEET[row,GDRIVE_CRM_STATUS_COL], email_sent: "" }
      if not GDRIVE_CRM_WORKSHEET[row,GDRIVE_CRM_EMAIL_SENT_COL].empty?
        dupe[:email_sent] = "!"
      end
      if dupe_hash[id_key].nil?
        dupe_hash[id_key] = [ dupe ]
      else
        dupe_hash[id_key] << dupe
      end
    end
    dupe_hash
  end
 
  def reload
    GDRIVE_CRM_WORKSHEET.reload
    redirect_to action: "index"
  end

  def row_link(row)
    "<a href=\"#{url_for action: "index", row: row}\">#{row}</a>"
  end

  def updateemail
    if params[:row] and params[:email]
      GDRIVE_CRM_WORKSHEET[params[:row].to_i,GDRIVE_CRM_EMAIL_COL] = params[:email]
      GDRIVE_CRM_WORKSHEET.save
      flash[:notice] = "Email updated for row #{row_link(params[:row])}".html_safe
    end
    redirect_to action: "index", row: params[:row]
  end

  def status
    if params[:email_content] and params[:button] == "Send"
      @email_content = FeedbackMailer.content_for_status(params[:status])
      @worksheet = GDRIVE_CRM_WORKSHEET
      @active_row = params[:row].to_i
      FeedbackMailer.feedback_email(params[:email_recipient],params[:email_content]).deliver
      flash[:notice] = "Email sent for row #{row_link(@active_row)} and status saved.".html_safe
      
      GDRIVE_CRM_WORKSHEET[params[:row].to_i,GDRIVE_CRM_EMAIL_SENT_COL] = Time.now.to_s
      # DROP DOWN AND SAVE STATUS
    elsif params[:email] == "Edit" or GDRIVE_CRM_STATUS_REQUIRES_EDIT.index(params[:status])
      # Show the email and allow editing.
      @worksheet = GDRIVE_CRM_WORKSHEET
      @active_row = params[:row].to_i
      if params[:email_content]
        @email_content = params[:email_content]
      else
        @email_content = FeedbackMailer.content_for_status(params[:status])
      end
      if params[:email_recipient]
        @email_recipient = params[:email_recipient]
      else
        @email_recipient = @worksheet[@active_row,GDRIVE_CRM_EMAIL_COL]
      end
      @other_feedback = []

      # GO NO FURTHER
      return
    end

    GDRIVE_CRM_WORKSHEET[params[:row].to_i,GDRIVE_CRM_STATUS_COL] = params[:status]
    GDRIVE_CRM_WORKSHEET.save
    flash[:notice] = "Status saved for row #{row_link(params[:row])}".html_safe if flash[:notice].nil?
    redirect_to action: "index"
  end
end
