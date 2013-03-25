# Copy these lines below and enter your own values
# GDRIVE_CRM_SESSION = GoogleDrive.login("youremail","applicationspecificpassword")
# GDRIVE_CRM_SPREADSHEET_KEY="yourspreadsheetkey"
# GDRIVE_CRM_WORKSHEET_INDEX=0 # Index of the worksheet in the spreadsheet
# GDRIVE_CRM_STATUS_COL=15 # Column containing status of entry
# GDRIVE_CRM_EMAIL_COL=3 # Column containing client's email address
# GDRIVE_CRM_DEVICEID_COL=4 # Column containing client's unique device ID (or some similar identifier that's guaranteed to be present)
# GDRIVE_CRM_EMAIL_SENT_COL=16 # Column that identifies if an email has been sent
# GDRIVE_CRM_MAJOR_COLS=[3,5,7,8,9,14] # Columns you want to see first
# GDRIVE_CRM_AUTOHANDLE_REQUIRED_COLUMNS=[2,3,5,6,7,8,9] # If none of these columns have values, the row can be automatically ignored
# GDRIVE_CRM_HEADER_ROW=true # Does the worksheet have a header column
# GDRIVE_CRM_WORKSHEET=GDRIVE_CRM_SESSION.spreadsheet_by_key(GDRIVE_CRM_SPREADSHEET_KEY).worksheets[GDRIVE_CRM_WORKSHEET_INDEX]
# GDRIVE_CRM_HANDLED_STATUS="H" # Mark a row as already handled with this status
# GDRIVE_CRM_DUPLICATE_STATUS="Duplicate" # This status means the row is a duplicate of another row, may be automatically set or manually set if similar enough
# Following is your list of statuses
# GDRIVE_CRM_POSSIBLE_STATUSES=["Mobile","General","H264","Hardware","Unsupported","Crash","Disconnect","Mobile","Sound","WorksForMe","KnownIssue","UsernameandPassword","Controls","Typo","Duplicate","Special"]
# Following is the list of statuses that require an email to be sent
# GDRIVE_CRM_EMAIL_STATUSES=["Mobile","General","H264","Hardware","Unsupported","Crash","Disconnect","Mobile","Sound","WorksForMe","KnownIssue","UsernameandPassword","Controls","Reboot"]
# GDRIVE_CRM_STATUS_REQUIRES_EDIT=["Typo","Special"] # These statuses will force you to edit and send an email
# GDRIVE_CRM_STATUS_TEMPLATE_MAP={"Special" => "Basic Outline"} # If a status doesn't match a filename, use this hash to map it
# GDRIVE_CRM_LINK_COLS=[7] # These columns contain links, CRM will add http:// if missing
# GDRIVE_CRM_IDENTIFYING_COLS=[4,3] # These columns identify a client, entries by the same client will be highlighted
# GDRIVE_CRM_EMAIL_TEMPLATES_BASE should point at a directory full of markdown files
# with filenames matching the statuses, can be whatever makes sense for you
# GDRIVE_CRM_EMAIL_TEMPLATES_BASE=Rails.root.join('app', 'assets', 'mytemplates', 'Email-Templates')
# GDRIVE_CRM_EMAIL_FROM="youremail@example.com"
# GDRIVE_CRM_EMAIL_FROM_NAME="Your Name"
# GDRIVE_CRM_EMAIL_SUBJECT="Your Email Subject"

## Local config below
## Local config finished

