class ColumnTitle < ActiveRecord::Base
  #attr_accessible :column, :title

  def self.title_for_column(column)
    column_title = ColumnTitle.where( column: column ).first
    column_title ? column_title.title : "Column #{column}"
  end
end
