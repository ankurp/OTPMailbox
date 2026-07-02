class RenameOtpRecordsToOneTimePasswords < ActiveRecord::Migration[8.1]
  def up
    if table_exists?(:otp_records) && !table_exists?(:one_time_passwords)
      rename_table :otp_records, :one_time_passwords
    end
  end

  def down
    if table_exists?(:one_time_passwords) && !table_exists?(:otp_records)
      rename_table :one_time_passwords, :otp_records
    end
  end
end
