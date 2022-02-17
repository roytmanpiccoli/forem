require "active_support/core_ext/integer/time"

# The test environment is used exclusively to run your application's
# test suite. You never need to work with it otherwise. Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs. Don't rely on the data there!

# rubocop:disable Metrics/BlockLength
Rails.application.configure do
  config.app_domain = ENV["APP_DOMAIN"] || "test.host"

  # Settings specified here will take precedence over those in config/application.rb.

  # cache_classes should be false when Spring is enabled, and true when it's disabled
  # https://guides.rubyonrails.org/configuring.html#config-cache-classes
  config.cache_classes = ActiveModel::Type::Boolean.new.cast(ENV["DISABLE_SPRING"])

  # See https://github.com/rails/rails/issues/40613#issuecomment-727283155
  config.action_view.cache_template_loading = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=#{1.hour.to_i}"
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
  config.cache_store = :null_store

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Additional setting to make test work. This is possibly useless and can be deleted.
  config.action_mailer.default_url_options = { host: config.app_domain }

  # Randomize the order test cases are executed.
  config.active_support.test_order = :random

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Debug is the default log_level, but can be changed per environment.
  config.log_level = :debug

  # Raises error for missing translations.
  config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names
  # config.action_view.annotate_rendered_view_with_filenames = true

  # enable Bullet in testing mode only if requested
  config.after_initialize do
    Bullet.enable = true
    Bullet.raise = true

    Bullet.add_safelist(type: :unused_eager_loading, class_name: "ApiSecret", association: :user)
    # acts-as-taggable-on has super weird eager loading problems: <https://github.com/mbleigh/acts-as-taggable-on/issues/91>
    Bullet.add_safelist(type: :n_plus_one_query, class_name: "ActsAsTaggableOn::Tagging", association: :tag)
    # Suppress incorrect warnings from Bullet due to included columns: https://github.com/flyerhzm/bullet/issues/147
    Bullet.add_safelist(type: :unused_eager_loading, class_name: "Article", association: :top_comments)
    Bullet.add_safelist(type: :unused_eager_loading, class_name: "Article", association: :collection)
    Bullet.add_safelist(type: :unused_eager_loading, class_name: "Comment", association: :user)
    # @citizen428: We have not yet resolved all user - profile preloads related to profile generalization
    Bullet.add_safelist(type: :n_plus_one_query, class_name: "User", association: :profile)
    Bullet.add_safelist(type: :n_plus_one_query, class_name: "Profile", association: :user)
    Bullet.add_safelist(type: :n_plus_one_query, class_name: "User", association: :setting)
    Bullet.add_safelist(type: :n_plus_one_query, class_name: "User", association: :notification_setting)
    # @mstruve: These occur during setting updates, not sure how since we are only dealing with single setting records
    Bullet.add_safelist(type: :n_plus_one_query, class_name: "Users::Setting", association: :user)
    Bullet.add_safelist(type: :n_plus_one_query, class_name: "Users::NotificationSetting", association: :user)
  end
end
# rubocop:enable Metrics/BlockLength
Rails.application.routes.default_url_options = { host: Rails.application.config.app_domain }
