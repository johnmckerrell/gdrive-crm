#!/usr/bin/env ruby

APP_PATH = File.expand_path('../../../config/application',  __FILE__)
require File.expand_path('../../../config/boot',  __FILE__)
require APP_PATH
# set Rails.env here if desired
Rails.application.require_environment!

Feedback.import_spreadsheet(true,ARGV[0],ARGV[1])
