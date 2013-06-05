class EmailAttempt < ActiveRecord::Base
  belongs_to :feedback
  attr_accessible :email_address, :email_content, :failure_status, :status

  def self.failure_status_options
    self.select("DISTINCT(failure_status)").map { |f| v = f.failure_status ? f.failure_status : ""; [v,v] }.sort { |a,b| a[1] <=> b[1] }
  end
end
