#!/usr/bin/env ruby

APP_PATH = File.expand_path('../../../config/application',  __FILE__)
require File.expand_path('../../../config/boot',  __FILE__)
require APP_PATH
# set Rails.env here if desired
Rails.application.require_environment!

class MailObserver
  def self.delivered_email(message)
    # Do whatever you want with the message in here
    puts "Mail delivered"
  end
end

ActionMailer::Base.register_observer(MailObserver)

filter_status = ARGV[0]


ws = GDRIVE_CRM_WORKSHEET
start_row = GDRIVE_CRM_HEADER_ROW ? 2 : 1
puts "Sending Emails"
puts "--------------"
puts
if filter_status
  puts "Filter: #{filter_status}:"
end
puts
start = Time.now
puts "Loading worksheet..."
ws.reload
puts "Done. (#{(Time.now-start).to_i}s)"
puts
for row in start_row..ws.num_rows

  status = ws[row, GDRIVE_CRM_STATUS_COL]
  email_sent = ws[row, GDRIVE_CRM_EMAIL_SENT_COL]
  email = ws[row, GDRIVE_CRM_EMAIL_COL]
  if status.nil? or status.empty? and email_sent and not email_sent.empty?
    puts "#{row.to_s.rjust(6)} Fixing stupid email sent (#{email_sent}) with no status (#{status})"
    ws[row, GDRIVE_CRM_EMAIL_SENT_COL] = ""
    ws.save
    next
  end
  if status.nil? or status.empty?
    #puts "Skipping as unhandled"
    next
  end
  if email_sent and not email_sent.empty?
    #puts "Skipping due to email_sent: #{email_sent}"
    next
  end
  if filter_status and status != filter_status
    #puts "Skipping due to filter_status: #{filter_status}, status=#{status}"
    next
  end
  if status == GDRIVE_CRM_HANDLED_STATUS
    ws[row, GDRIVE_CRM_EMAIL_SENT_COL] = "Skip"
    ws.save
    next
  end
  if not GDRIVE_CRM_EMAIL_STATUSES.index(status)
    puts "#{row.to_s.rjust(6)} Skipping #{email} due to not in email statuses (#{status})."
    ws[row, GDRIVE_CRM_EMAIL_SENT_COL] = "Skip"
    ws.save
    next
  end
  success = false
  begin
    email_content = FeedbackMailer.content_for_status(status)
    result = FeedbackMailer.feedback_email(email,email_content).deliver!
    #puts "Email sending result:#{result}:"
    puts "#{row.to_s.rjust(6)} Would send to #{email} for #{status}"
    success = true
  rescue Exception => e
    p e
  end
  ws[row, GDRIVE_CRM_EMAIL_SENT_COL] = success ? Time.now.to_s : "Fail"
  ws.save
end

