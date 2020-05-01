HealthCheck.setup do |config|
  config.standard_checks = [ "database", "migrations"]
  config.full_checks = [ "database", "migrations"]
end