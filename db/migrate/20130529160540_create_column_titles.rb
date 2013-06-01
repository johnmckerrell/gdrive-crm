class CreateColumnTitles < ActiveRecord::Migration
  def change
    create_table :column_titles do |t|
      t.integer :column
      t.string :title

      t.timestamps
    end
  end
end
