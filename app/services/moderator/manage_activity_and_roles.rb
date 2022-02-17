module Moderator
  class ManageActivityAndRoles
    attr_reader :user, :admin, :user_params

    def initialize(user:, admin:, user_params:)
      @user = user
      @admin = admin
      @user_params = user_params
    end

    def self.handle_user_roles(admin:, user:, user_params:)
      new(user: user, admin: admin, user_params: user_params).update_roles
    end

    def delete_comments
      Users::DeleteComments.call(user)
    end

    def delete_articles
      Users::DeleteArticles.call(user)
    end

    def delete_user_activity
      Users::DeleteActivity.call(user)
    end

    def remove_privileges
      @user.remove_role(:workshop_pass)
      remove_mod_roles
      remove_tag_moderator_role
    end

    def remove_mod_roles
      @user.remove_role(:trusted)
      @user.remove_role(:tag_moderator)
      @user.notification_setting.update(email_tag_mod_newsletter: false)
      Mailchimp::Bot.new(user).manage_tag_moderator_list
      @user.notification_setting.update(email_community_mod_newsletter: false)
      Mailchimp::Bot.new(user).manage_community_moderator_list
    end

    def remove_tag_moderator_role
      @user.remove_role(:tag_moderator)
      Mailchimp::Bot.new(user).manage_tag_moderator_list
    end

    def create_note(reason, content)
      Note.create(
        author_id: @admin.id,
        noteable_id: @user.id,
        noteable_type: "User",
        reason: reason,
        content: content,
      )
    end

    def handle_user_status(role, note)
      case role
      when "Suspend" || "Spammer"
        user.add_role(:suspended)
        remove_privileges
      when "Warn"
        warned
      when "Comment Suspend"
        comment_suspended
      when "Regular Member"
        regular_member
      when "Trusted"
        remove_negative_roles
        TagModerators::AddTrustedRole.call(user)
      when "Admin"
        check_super_admin
        remove_negative_roles
        user.add_role(:admin)
        TagModerators::AddTrustedRole.call(user)
      when "Super Admin"
        check_super_admin
        remove_negative_roles
        user.add_role(:super_admin)
        TagModerators::AddTrustedRole.call(user)
      when "Tech Admin"
        check_super_admin
        remove_negative_roles
        user.add_role(:tech_admin)
        # DataUpdateScripts falls under the admin namespace
        # and hence requires a single_resource_admin role to view
        # this technical admin resource
        user.add_role(:single_resource_admin, DataUpdateScript)
      when /^(Resource Admin: )/
        check_super_admin
        remove_negative_roles
        user.add_role(:single_resource_admin, role.split("Resource Admin: ").last.safe_constantize)
      end
      create_note(role, note)
    end

    def check_super_admin
      raise I18n.t("services.moderator.manage_activity_and_roles.need_super") unless @admin.super_admin?
    end

    def comment_suspended
      user.add_role(:comment_suspended)
      user.remove_role(:suspended)
      remove_privileges
    end

    def regular_member
      remove_negative_roles
      remove_mod_roles
    end

    def warned
      user.add_role(:warned)
      user.remove_role(:suspended)
      remove_privileges
    end

    def remove_negative_roles
      user.remove_role(:suspended) if user.suspended?
      user.remove_role(:warned) if user.warned?
      user.remove_role(:comment_suspended) if user.comment_suspended?
    end

    def update_trusted_cache
      Rails.cache.delete("user-#{@user.id}/has_trusted_role")
      @user.trusted?
    end

    def update_roles
      handle_user_status(user_params[:user_status], user_params[:note_for_current_role])
      update_trusted_cache
    end
  end
end
