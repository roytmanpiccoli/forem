# Rails 7 no longer autoloads application constants while initializers run (the main autoloader is
# set up after them), so the middleware classes are required explicitly before they are added to
# the stack. Zeitwerk skips constants that are already defined.
if Rails.env.production?
  require_relative "../../app/lib/middlewares/set_cookie_domain"
  Rails.configuration.middleware.use(Middlewares::SetCookieDomain)
end

# Include middleware to ensure timezone for browser requests for Capybara specs
# matches the random zonebie timezone set at the beginning of our spec run
if Rails.env.test?
  require_relative "../../app/lib/middlewares/set_time_zone"
  Rails.configuration.middleware.use(Middlewares::SetTimeZone)
end
