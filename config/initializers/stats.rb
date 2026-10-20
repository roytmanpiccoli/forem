# Rails 7 no longer autoloads application constants while initializers run (the main autoloader is
# set up after them), so the stats driver chain is required explicitly. Zeitwerk skips constants
# that are already defined.
require_relative "../../app/lib/acts_as_forem_stats_driver"
require_relative "../../app/lib/forem_stats_drivers/datadog_driver"
require_relative "../../app/lib/forem_stats_driver"

ForemStatsClient = ForemStatsDriver.new
