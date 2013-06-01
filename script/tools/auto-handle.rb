#!/usr/bin/env ruby

APP_PATH = File.expand_path('../../../config/application',  __FILE__)
require File.expand_path('../../../config/boot',  __FILE__)
require APP_PATH
# set Rails.env here if desired
Rails.application.require_environment!

require 'digest/md5'

puts "Auto Handling CRM Entries"
puts "-------------------------"
puts
Feedback.auto_handle
