#!/usr/bin/env ruby

APP_PATH = File.expand_path('../../../config/application',  __FILE__)
require File.expand_path('../../../config/boot',  __FILE__)
require APP_PATH
# set Rails.env here if desired
Rails.application.require_environment!

ws = GDRIVE_CRM_WORKSHEET
start_row = GDRIVE_CRM_HEADER_ROW ? 2 : 1
puts "Analysing CRM Entries"
puts "---------------------"
puts
start = Time.now
puts "Loading worksheet..."
ws.reload
puts "Done. (#{(Time.now-start).to_i}s)"
puts
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

counts = counts.values.sort do |a,b|
  c = a[:all] <=> b[:all]
  if c == 0
    c = a[:email_sent] <=> b[:email_sent]
  end
  c
end
counts.each do |count|
  puts "All: #{count[:all].to_s.rjust(5)}  Email Sent: #{count[:email_sent].to_s.rjust(5)} (#{((count[:email_sent].to_f/count[:all].to_f)*100).to_i.to_s.rjust(3)}%) - #{count[:status]}"
end
