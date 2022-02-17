module TagModerators
  class Remove
    def self.call(user, tag)
      user.remove_role(:tag_moderator, tag)
      if user.notification_setting.email_tag_mod_newsletter?
        user.notification_setting.update(email_tag_mod_newsletter: false)
      end
      Rails.cache.delete("user-#{user.id}/tag_moderators_list")
      return unless tag_mod_newsletter_enabled?

      Mailchimp::Bot.new(user).manage_tag_moderator_list
    end

    def self.tag_mod_newsletter_enabled?
      Settings::General.mailchimp_api_key.present? &&
        Settings::General.mailchimp_tag_moderators_id.present?
    end
    private_class_method :tag_mod_newsletter_enabled?
  end
end
