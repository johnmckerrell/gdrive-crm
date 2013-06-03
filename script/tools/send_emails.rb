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


puts "Sending Emails"
puts "--------------"
puts
if filter_status
  puts "Filter: #{filter_status}:"
end
puts
conditions = [ "status <> '' AND email_status IS NULL" ]
if filter_status
  conditions = [ "status = ? AND email_status IS NULL", filter_status ]
end
Feedback.find(:all, :conditions => conditions).each do |feedback|
  if feedback.status == GDRIVE_CRM_HANDLED_STATUS
    feedback.email_status = 'skip'
    feedback.save
    next
  end
  if not GDRIVE_CRM_EMAIL_STATUSES.index(feedback.status)
    puts "#{feedback.id.to_s.rjust(6)} Skipping #{feedback.email_address} due to not in email statuses (#{feedback.status})."
    feedback.email_status = 'skip'
    feedback.save
    next
  end
  begin
    email_content = FeedbackMailer.content_for_status(feedback.status)
    ea = EmailAttempt.new
    ea.feedback = feedback
    ea.email_address = feedback.email_address
    ea.email_content = email_content
    begin
      result = FeedbackMailer.feedback_email(feedback.email_address,email_content).deliver!
      ea.status = 'success'
      puts "#{feedback.id.to_s.rjust(6)} did send to #{feedback.email_address} for #{feedback.status}"
    rescue Exception => e
      p "Email send failed: #{e.inspect}"
      ea.status = 'failed'
      ea.failure_status = 'unknown'
      puts "#{feedback.id.to_s.rjust(6)} failed to send to #{feedback.email_address} for #{feedback.status}"
    end
    ea.save!
    feedback.email_status = ea.status
    feedback.save!
    #puts "Email sending result:#{result}:"
    success = true
  rescue Exception => e
    p e
  end
end

