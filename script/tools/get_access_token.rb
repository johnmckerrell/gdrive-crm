#!/usr/bin/env ruby

APP_PATH = File.expand_path('../../../config/application',  __FILE__)
require File.expand_path('../../../config/boot',  __FILE__)
require APP_PATH
# set Rails.env here if desired
Rails.application.require_environment!

# Authorizes with OAuth and gets an access token.
client = Google::APIClient.new
auth = client.authorization
auth.client_id = GDRIVE_CRM_CLIENT_ID
auth.client_secret = GDRIVE_CRM_CLIENT_SECRET
auth.scope = [
    "https://www.googleapis.com/auth/drive",
    "https://spreadsheets.google.com/feeds/"
]
auth.redirect_uri = "urn:ietf:wg:oauth:2.0:oob"
print("1. Open this page:\n%s\n\n" % auth.authorization_uri)
print("2. Enter the authorization code shown in the page: ")
auth.code = $stdin.gets.chomp
auth.fetch_access_token!
access_token = auth.access_token

File.open(GDRIVE_CRM_ACCESS_KEY_FILE, 'w') { |f| f.write(access_token) }
puts "Access token saved to #{GDRIVE_CRM_ACCESS_KEY_FILE}"
