class EmailAttempt < ActiveRecord::Base
  belongs_to :feedback
  attr_accessible :email_address, :email_content, :failure_status, :status
end
