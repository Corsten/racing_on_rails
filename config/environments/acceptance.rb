config.cache_classes = true
config.whiny_nils = true

config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = true

config.action_controller.allow_forgery_protection    = false
config.action_mailer.delivery_method = :test

config.gem "json_pure"
config.gem "selenium-webdriver"
config.gem "mocha"
config.gem "minitest", :lib => "minitest/unit"
