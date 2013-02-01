class FeedbackController < ApplicationController

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
      if params[:row].to_i > 0 and params[:row].to_i < @worksheet.num_rows
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
      if GDRIVE_CRM_IDENTIFYING_COLS
        this_ids = GDRIVE_CRM_IDENTIFYING_COLS.map { |col| @worksheet[@active_row,col] }
        this_ids.delete_if { |val| val.nil? || val == "" }
        start_row = GDRIVE_CRM_HEADER_ROW ? 2 : 1
        for row in start_row..@worksheet.num_rows
          ids = GDRIVE_CRM_IDENTIFYING_COLS.map { |col| @worksheet[row,col] }
          ids.delete_if { |val| val.nil? || val == "" }

          @other_feedback << row if ((this_ids & ids).length > 0)
        end
      end
    end
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
      
      GDRIVE_CRM_WORKSHEET[params[:row].to_i,GDRIVE_CRM_EMAIL_SENT_COL] = "Yes"
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
