class FeedbackMailer < ActionMailer::Base
  default from: "#{GDRIVE_CRM_EMAIL_FROM_NAME} <#{GDRIVE_CRM_EMAIL_FROM}>"

  def self.cname(name, char_white_sub = '-', char_other_sub = '-')
    name.respond_to?(:gsub) ?
      name.gsub(%r{\s},char_white_sub).gsub(%r{[<>+]}, char_other_sub).downcase :
      ''
  end

  def self.content_for_status(status)
    status = GDRIVE_CRM_STATUS_TEMPLATE_MAP[status] if GDRIVE_CRM_STATUS_TEMPLATE_MAP[status]
    filename = GDRIVE_CRM_EMAIL_TEMPLATES_BASE.join(self.cname(status)).sub_ext(".md")
    skipped_head = false
    started_content = false
    content = ''
    File.open(filename).each_line do |line|
      if line.chomp == "--"
        skipped_head = true
      elsif ! started_content and line.chomp == ''
        # Do nothing, skip
      elsif skipped_head
        started_content = true
        content += line.gsub(/^\\/,'')
      end
    end
    content = "" if content.nil?
    #content.gsub(/^.*?--/m, '')
    content
  end

  def feedback_email(to, content)
    mail( to: to, subject: GDRIVE_CRM_EMAIL_SUBJECT ) do |format|
      format.text { render text: content }
      format.html { render text: GitHub::Markdown.render(content) }
    end
  end

end
