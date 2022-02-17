# We want to check not only if we are in the test environment, but also if we are
# running E2E tests. Otherwise this will run when system tests run.
return unless Rails.env.test? && ENV["E2E"].present?

# Explicitly requiring lib/cypress-rails to load monkey-patch
Dir.glob(Rails.root.join("lib/cypress-rails/*.rb")).each do |filename|
  require_dependency filename
end

# rubocop:disable Rails/Output

CypressRails.hooks.before_server_start do
  # Called once, before either the transaction or the server is started
  puts "Starting up server for end to end tests."

  Rails.application.load_tasks

  if ENV["CREATOR_ONBOARDING_SEED_DATA"]
    Rake::Task["db:seed:e2e_creator_onboarding"].invoke
  else
    Rake::Task["db:seed:e2e"].invoke
  end
end

CypressRails.hooks.after_transaction_start do
  # Called after the transaction is started (at launch and after each reset)
end

CypressRails.hooks.after_state_reset do
  # Triggered after `/cypress_rails_reset_state` is called
end

CypressRails.hooks.before_server_stop do
  # Called once, at_exit
  puts "Cleaning up and stopping server for end to end tests."
  Rake::Task["db:truncate_all"].invoke if ENV["SKIP_SEED_DATA"].blank?
  puts "The end to end test server shutdown gracefully."
end

# rubocop:enable Rails/Output
