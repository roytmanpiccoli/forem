class ChangeLastModerationNotificationDefaultOnUser < ActiveRecord::Migration[5.1]
  def up
    change_column_default :users, :last_moderation_notification, Time.new("2017-01-01")
  end

  def down
    change_column_default :users, :last_moderation_notification, Time.new("2017-01-01")
  end
end
