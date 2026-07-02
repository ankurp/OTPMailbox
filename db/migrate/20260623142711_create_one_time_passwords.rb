class CreateOneTimePasswords < ActiveRecord::Migration[8.1]
  def change
    create_table :one_time_passwords do |t|
      t.string :recipient_email, null: false
      t.string :otp_code, null: false
      t.string :subject
      t.string :sender_email
      t.datetime :received_at, null: false

      t.timestamps
    end

    add_index :one_time_passwords, :recipient_email
    add_index :one_time_passwords, :received_at
  end
end
