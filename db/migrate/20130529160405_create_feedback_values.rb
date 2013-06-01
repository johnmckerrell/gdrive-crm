class CreateFeedbackValues < ActiveRecord::Migration
  def change
    create_table :feedback_values do |t|
      t.references :feedback, :null => false
      t.integer :column, :null => false
      t.string :value, :null => false

      t.timestamps
    end
  end
end
