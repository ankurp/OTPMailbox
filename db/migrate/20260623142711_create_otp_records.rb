class CreateOtpRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :otp_records do |t|
      t.string :recipient_email, null: false
      t.string :otp_code, null: false
      t.string :subject
      t.string :sender_email
      t.datetime :received_at, null: false

      t.timestamps
    end

    add_index :otp_records, :recipient_email
    add_index :otp_records, :received_at
  end
end
