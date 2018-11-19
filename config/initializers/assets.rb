# frozen_string_literal: true

Rails.application.config.assets.paths << Rails.root.join("node_modules")
Rails.application.config.assets.version = "3.2"

Rails.application.configure do
  config.assets.precompile += %w[
    admin.js
    apple-touch-icon.png
    favicon.ico
    racing_association.css
    racing_association.js
  ]
  config.assets.precompile << /.*\.png$/
  config.assets.precompile << /.*\.jpg$/
end
