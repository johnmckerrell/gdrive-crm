class CreateEmailAttempts < ActiveRecord::Migration
  def change
    create_table :email_attempts do |t|
      t.references :feedback, :null => false
      t.string :status
      t.string :failure_status
      t.string :email_address
      t.text :email_content

      t.timestamps
    end
  end
end
