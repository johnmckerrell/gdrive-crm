class FeedbackController < ApplicationController

  def analyse
    ws = GDRIVE_CRM_WORKSHEET
    start_row = GDRIVE_CRM_HEADER_ROW ? 2 : 1
    @start = Time.now
    counts = {"Total" => { all: 0, email_sent: 0, status: "Total"} }
    for row in start_row..ws.num_rows

      status = ws[row, GDRIVE_CRM_STATUS_COL]
      email_sent = ws[row, GDRIVE_CRM_EMAIL_SENT_COL]
      if counts[status].nil?
        counts[status] = { all: 0, email_sent: 0, status: status }
      end
      counts[status][:all] += 1
      counts[status][:email_sent] += 1 if email_sent and not email_sent.empty?
      counts["Total"][:all] += 1
      counts["Total"][:email_sent] += 1 if email_sent and not email_sent.empty?
    end

    @counts = counts.values.sort do |a,b|
      c = a[:all] <=> b[:all]
      if c == 0
        c = a[:email_sent] <=> b[:email_sent]
      end
      c
    end
  end

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
      @count_left = 0
      for row in 1..@worksheet.num_rows
        status = @worksheet[row, GDRIVE_CRM_STATUS_COL]
        if status.empty?
          @count_left += 1
        end
       end
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
    generate_dupe_hash()[generate_id_key(active_row)]
  end

  def generate_id_key(row)
      GDRIVE_CRM_WORKSHEET[row,GDRIVE_CRM_DEVICEID_COL]
  end

  def generate_dupe_hash()
    dupe_hash = {}
    start_row = GDRIVE_CRM_HEADER_ROW ? 2 : 1
    for row in start_row..GDRIVE_CRM_WORKSHEET.num_rows
      dupes = nil
      # Find the existing dupes
      GDRIVE_CRM_IDENTIFYING_COLS.each do |id_col|
        id_val = GDRIVE_CRM_WORKSHEET[row,id_col]
        next if id_val.empty?

        existing = dupe_hash[id_val]
        if existing == dupes
        elsif existing and dupes
          existing.concat(dupes)
          dupes = existing
        elsif existing
          dupes = existing
        end
      end

      # Add this row
      dupe = { row: row, status: GDRIVE_CRM_WORKSHEET[row,GDRIVE_CRM_STATUS_COL], email_sent: "", email_failed: false }
      if not GDRIVE_CRM_WORKSHEET[row,GDRIVE_CRM_EMAIL_SENT_COL].empty?
        dupe[:email_sent] = "!"
      end
      if GDRIVE_CRM_WORKSHEET[row,GDRIVE_CRM_EMAIL_SENT_COL].match(/fail/i)
        dupe[:email_failed] = true
      end
      if dupes.nil?
        dupes = [ dupe ]
      else
        dupes << dupe
      end

      # Make sure the dupes are saved in the hash
      GDRIVE_CRM_IDENTIFYING_COLS.each do |id_col|
        id_val = GDRIVE_CRM_WORKSHEET[row,id_col]
        next if id_val.empty?

        dupe_hash[id_val] = dupes
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
