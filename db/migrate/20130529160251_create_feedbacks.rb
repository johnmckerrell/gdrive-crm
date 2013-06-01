class CreateFeedbacks < ActiveRecord::Migration
  def change
    create_table :feedbacks do |t|
      t.string :original_email, :null => false
      t.string :email_address, :null => false
      t.string :device_udid, :null => false
      t.datetime :submitted_at, :null => false
      t.string :status
      t.string :email_status

      t.timestamps

    end
    add_index :feedbacks, [ :device_udid, :submitted_at ], :unique => true
    add_index :feedbacks, [ :original_email, :email_address ]
  end
end
