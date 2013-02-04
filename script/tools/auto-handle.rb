#!/usr/bin/env ruby

APP_PATH = File.expand_path('../../../config/application',  __FILE__)
require File.expand_path('../../../config/boot',  __FILE__)
require APP_PATH
# set Rails.env here if desired
Rails.application.require_environment!

ws = GDRIVE_CRM_WORKSHEET
start_row = GDRIVE_CRM_HEADER_ROW ? 2 : 1
puts "Auto Handling CRM Entries"
puts "-------------------------"
puts
puts "Loading worksheet..."
ws.reload
puts "Done."
puts
if GDRIVE_CRM_HEADER_ROW
  headers = []
  for col in 1..ws.num_cols
    headers << ws[1, col]
  end
  puts headers.join(',')
end
for row in start_row..ws.num_rows

  status = ws[row, GDRIVE_CRM_STATUS_COL]
  if status.nil? or status.strip.empty?
    ignore = false
    GDRIVE_CRM_AUTOHANDLE_REQUIRED_COLUMNS.each do |col|
      val = ws[row,col]
      if val and not val.strip.empty?
        ignore = true
        break
      end
    end
    unless ignore
      vals = [row]
      for col in 1..ws.num_cols
        vals << ws[row,col]
      end
      puts vals.join(',')
      ws[row, GDRIVE_CRM_STATUS_COL] = GDRIVE_CRM_HANDLED_STATUS
      ws.save
    end
  end
end
