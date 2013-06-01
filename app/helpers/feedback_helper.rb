module FeedbackHelper
  def header(col)
    ColumnTitle.title_for_column(col)
  end

  def calculate_size(value,max_cols=nil)
    max = 0
    value = value.gsub(/\r\n/m,"\n").gsub(/\r/m,"\n")
    if max_cols
      value = word_wrap(value,line_width: max_cols)
    end
    lines = value.split(/[\r\n]/m)
    lines.each do |line|
      max = line.length if line.length > max
    end
    { rows: lines.length, cols: max }
  end

  def text_tag_for_size(size, value, other = {})
    max = other[:max]
    if size[:rows] > 1 or (max and max[:cols] < size[:cols])
      if max and max[:cols] > size[:cols]
        text_area_tag "", value, :rows => size[:rows], :cols => max[:cols], :disabled => "disabled", :wrap => "hard"
      else
        text_area_tag "", value, :rows => size[:rows], :cols => size[:cols], :disabled => "disabled"
      end
    else
      text_field_tag "", value, :size => ( size[:cols] > 0 ? size[:cols] : 1 ), :disabled => "disabled"
    end
  end
  def generate_link(url)
    url = url.strip
    if url.length == 0
      return ""
    elsif url.match(/^http:/)
      if url.match(/^http:[^\/]/)
        url.gsub(/^http:/, 'http://')
      end
    else
      url = "http://#{url}"
    end
    link_to "link", url, target: "_blank", :onmouseup => "if (window.lastselect) window.lastselect.focus()"
  end
end
