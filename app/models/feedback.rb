class Feedback < ActiveRecord::Base
  #attr_accessible :device_udid, :email, :email_status, :original_email, :status, :submitted_at
  has_many :feedback_values
  has_many :email_attempts

  def self.import_spreadsheet(show_output, spreadsheet_key = nil, worksheet_index = nil)
    if spreadsheet_key
      spreadsheet = GDRIVE_CRM_SESSION.spreadsheet_by_key(ARGV[0])
      if worksheet_index and worksheet_index.match(/^[0-9]+/)
        ws = spreadsheet.worksheets[worksheet_index.to_i]
      else
        ws = spreadsheet.worksheets[GDRIVE_CRM_WORKSHEET_INDEX]
      end
    else
      ws = GDRIVE_CRM_WORKSHEET
    end
    ws.reload
    start_row = GDRIVE_CRM_HEADER_ROW ? 2 : 1
    if show_output
      puts "Importing Spreadsheet Data"
      puts "--------------------------"
      puts
      start = Time.now
      puts "Loading worksheet..."
      ws.reload
      puts "Done. (#{(Time.now-start).to_i}s #{Time.now})"
      puts
    end

    if GDRIVE_CRM_HEADER_ROW
      db_titles = ColumnTitle.all
      titles = {}
      db_titles.each do |title|
        titles[title.column.to_s] = title.title
      end
      for col in 1..ws.num_cols
        if titles[col.to_s]
          if titles[col.to_s] != ws[1,col] and ws[1,col] and ws[1,col].length > 0
            raise Exception, "Titles have changed, can't be sure this will import right: '#{ws[1,col]}' != '#{titles[col.to_s]}'"
          end
        else
          title = ColumnTitle.new
          title.column = col
          title.title = ws[1,col]
          title.save!
        end
      end
    end

    counts = { imported: 0, ignored: 0 }

    for row in start_row..ws.num_rows
      vals = []
      for col in 1..ws.num_cols
        vals << ws[row,col]
      end

      Feedback.import_row(vals, counts)
    end

    overview = "Successfully imported: #{counts[:imported]} (Ignored: #{counts[:ignored]}, Total: #{(counts[:ignored]+counts[:imported])})"
    puts overview if show_output
    handle_output = Feedback.auto_handle
    puts handle_output if show_output
    overview
  end

  def self.import_row(import_vals,counts = nil)
    if counts.nil?
      counts = {}
    end
    if counts[:imported].nil?
      counts[:imported] = 0
    end
    if counts[:ignored].nil?
      counts[:ignored] = 0
    end
    f = Feedback.new
    ea = nil
    vals = []
    col_adjust = 0
    backup_udid = nil
    for index in 0..import_vals.length
      col = index+1
      GDRIVE_CRM_SKIPPED_COLUMN_CHECKS.each do |skip_check|
          val = import_vals[index+col_adjust]
          if val
            val = val.strip
          else
            val = ""
          end
          if skip_check[:column] == col and ! val.match(Regexp.new(skip_check[:format]))
              #puts "row #{row} val (#{val}) does not match #{skip_check[:format]}"
              col_adjust -= 1
          end
      end
      val = import_vals[index+col_adjust]
      if val
        val = val.strip
      else
        val = ""
      end
      if col == GDRIVE_CRM_BACKUP_DEVICEID_COL
        backup_udid = val
      end
      if col == GDRIVE_CRM_EMAIL_SENT_COL
        if val and val.length > 0
          status = "success"
          if val.match(/skip/i)
            status = "skip"
          elsif val.match(/fail/i)
            status = "failed"
          end
          begin
            email_time = Time.parse(val)
          rescue Exception
            email_time = nil
          end
          if email_time
            ea = EmailAttempt.new
            ea.feedback = f
            ea.status = status
            ea.email_address = f.email_address
            ea.failure_status = status == "failed" ? "unknown" : nil
            ea.created_at = email_time
          end
          f.email_status = status
        end
      else
        vals << f.set_value_for_column(col,val)
      end
    end

    begin
      if ( f.device_udid.nil? or f.device_udid.empty? )
          f.device_udid = backup_udid
          puts "Replacing blank udid with #{backup_udid}"
      end
      f.save!
      if ea
        ea.feedback = f
        ea.save!
      end
      vals.each do |v|
        next unless v
        v.feedback = f
        v.save!
      end
      counts[:imported] +=1
    rescue ArgumentError
      puts "Problem with record: #{f.inspect}"
      counts[:ignored] += 1
    rescue ActiveRecord::RecordNotUnique
      counts[:ignored] += 1
    end
  end

  def self.auto_handle
    text = ''
    first_matches = {}
    unhandled = Feedback.includes(:feedback_values).where("status = ''").order("id ASC")

    unhandled.each do |feedback|
      status = feedback.status
      if status.nil? or status.strip.empty?
        ignore = false
        vals = []
        GDRIVE_CRM_AUTOHANDLE_REQUIRED_COLUMNS.each do |col|
          val = feedback.value_for_column(col)
          if val and not val.empty?
            ignore = true
          end
          vals << val
        end
        if ignore
          digest = Digest::MD5.hexdigest(vals.join(','))
          if first_matches[digest]
            text += "Dupe found, #{feedback.id} = #{first_matches[digest]}\n"
            feedback.status = GDRIVE_CRM_DUPLICATE_STATUS
            feedback.save!
          else
            first_matches[digest] = feedback.id
          end
        else # ignore
          puts "#{feedback.inspect}\n"
          feedback.status = GDRIVE_CRM_HANDLED_STATUS
          feedback.save!
        end
      end
    end
    #puts "first_matches=#{first_matches.inspect}"
    text
  end

  def self.analyse

    text = "Analysing CRM Entries\n"
    text += "---------------------\n"
    text += "\n"
    counts = {"Total" => { all: 0, email_sent: 0, status: "Total"} }

    totals = ActiveRecord::Base.connection.select_all "SELECT status, email_status, COUNT(*) feedback_count FROM feedbacks GROUP BY status, email_status"

    totals.each do |total|
      counts["Total"][:all] += total["feedback_count"]

      if counts[total["status"]].nil?
        counts[total["status"]] = { all: 0, email_sent: 0, status: total["status"] }
      end
      counts[total["status"]][:all] += total["feedback_count"]
      unless (total["email_status"].nil? or total["email_status"].empty?)
        counts["Total"][:email_sent] += total["feedback_count"]
        counts[total["status"]][:email_sent] += total["feedback_count"]
      end
    end


    counts = counts.values.sort do |a,b|
      c = a[:all] <=> b[:all]
      if c == 0
        c = a[:email_sent] <=> b[:email_sent]
      end
      c
    end
    counts.each do |count|
      text += "All: #{count[:all].to_s.rjust(5)}  Email Sent: #{count[:email_sent].to_s.rjust(5)} (#{((count[:email_sent].to_f/count[:all].to_f)*100).to_i.to_s.rjust(3)}%) - #{count[:status]}\n"
    end

    text
  end

  def set_value_for_column(col,val)
    if col == GDRIVE_CRM_STATUS_COL
      self.status = val
    elsif col == GDRIVE_CRM_EMAIL_COL
      self.email_address = val
      self.original_email = val
    elsif col == GDRIVE_CRM_DEVICEID_COL
      self.device_udid = val
    elsif col == GDRIVE_CRM_TIMESTAMP_COL
      begin
        if val.length < 12
          self.submitted_at = Time.strptime(val,'%m/%d/%Y')
        elsif val.length == 25
          self.submitted_at = Time.parse(val)
        else
          self.submitted_at = Time.strptime(val,'%m/%d/%Y %H:%M:%S')
        end
      rescue Exception
        raise "Invalid time string: '#{val}'"
      end
    else
      fv = FeedbackValue.new
      fv.column = col
      fv.value = val
      return fv
    end
    return nil
  end

  def value_for_column(col)
    if col == GDRIVE_CRM_STATUS_COL
      self.status
    elsif col == GDRIVE_CRM_EMAIL_COL
      self.email_address
    elsif col == GDRIVE_CRM_DEVICEID_COL
      self.device_udid
    elsif col == GDRIVE_CRM_TIMESTAMP_COL
      self.submitted_at
    elsif col == GDRIVE_CRM_EMAIL_SENT_COL
      self.email_status
    else
      if self.feedback_values.loaded?
        val = self.feedback_values.detect { |v|  v.column == col }#.find(:first, :conditions => { :column => col })
      else
        val = self.feedback_values.where({ :column => col }).first
      end
      val.value if val
    end
  end

  def self.email_status_options
    Feedback.select("DISTINCT(email_status)").map { |f| v = f.email_status ? f.email_status : ""; [v,v] }.sort { |a,b| a[1] <=> b[1] }
  end

  def self.generate_monthly_stats
    ActiveRecord::Base.connection.select_all "SELECT COUNT(*) `count`, DATE_FORMAT(submitted_at, '%Y-%m') AS `time_period` FROM feedbacks GROUP BY DATE_FORMAT(submitted_at, '%Y-%m')"
  end

  def self.generate_daily_stats
    ActiveRecord::Base.connection.select_all "SELECT COUNT(*) `count`, DATE_FORMAT(submitted_at, '%Y-%m-%d') AS `time_period` FROM feedbacks WHERE submitted_at > DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 8 DAY), '%Y-%m-%d') GROUP BY DATE_FORMAT(submitted_at, '%Y-%m-%d')"
  end

  def self.generate_hourly_stats
    ActiveRecord::Base.connection.select_all "SELECT COUNT(*) `count`, DATE_FORMAT(submitted_at, '%Y-%m-%d %H') AS `time_period` FROM feedbacks WHERE submitted_at > DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 8 DAY), '%Y-%m-%d') GROUP BY DATE_FORMAT(submitted_at, '%Y-%m-%d %H')"
  end

  def self.save_monthly_stats
    filename = "public/stats/monthly.js"
    File.open(filename,"w") { |f| f.write("var monthly_stats = "+self.generate_monthly_stats.to_json) }
  end

  def self.save_hourly_stats
    filename = "public/stats/hourly.js"
    File.open(filename,"w") { |f| f.write("var hourly_stats = "+self.generate_monthly_stats.to_json) }
  end

end
