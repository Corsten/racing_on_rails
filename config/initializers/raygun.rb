# frozen_string_literal: true

if Rails.env.production?
  Raygun.setup do |config|
    config.api_key = "jXyEmb3vjngvdkib6L4O6w=="
  end
end
