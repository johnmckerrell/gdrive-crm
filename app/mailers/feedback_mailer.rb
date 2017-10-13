class FeedbackMailer < ActionMailer::Base
  default from: "#{GDRIVE_CRM_EMAIL_FROM_NAME} <#{GDRIVE_CRM_EMAIL_FROM}>"

  # Borrowed from Gollum
  def self.cname(name, char_white_sub = '-', char_other_sub = '-')
    name.respond_to?(:gsub) ?
      name.gsub(%r{\s},char_white_sub).gsub(%r{[<>+]}, char_other_sub).downcase :
      ''
  end

  def self.stripped_content_for_file(filename)
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
    content
  end

  def self.content_for_status(status,feedback)
    status = GDRIVE_CRM_STATUS_TEMPLATE_MAP[status] if GDRIVE_CRM_STATUS_TEMPLATE_MAP[status]
    filename = GDRIVE_CRM_EMAIL_TEMPLATES_BASE.join(self.cname(status)).sub_ext(".md")
    content = self.stripped_content_for_file(filename)
    footer_filename = GDRIVE_CRM_EMAIL_TEMPLATES_BASE.join("footer").sub_ext(".md")
    footer = self.stripped_content_for_file(footer_filename)
    footer = footer.gsub(/\{GDRIVE_CRM_FEEDBACK_ID\}/, feedback.id.to_s).gsub(/\{GDRIVE_CRM_FEEDBACK_TIMESTAMP\}/,feedback.submitted_at.to_s).gsub(/\{GDRIVE_CRM_FEEDBACK_COL_(\d+)\}/e) { |col| feedback.value_for_column($1.to_i)}
    #content.gsub(/^.*?--/m, '')
    content+"\n\n"+footer
  end

  def feedback_email(to, content)
    mail( to: to, subject: GDRIVE_CRM_EMAIL_SUBJECT ) do |format|
      format.text { render plain: content }
      format.html { render plain: GitHub::Markdown.render(content) }
    end
  end

end
