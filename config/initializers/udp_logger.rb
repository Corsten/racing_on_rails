# frozen_string_literal: true

if (Rails.env.test? || Rails.env.development?) && Rails.logger.level == 0
  ActiveSupport::Notifications.subscribe(/racing_on_rails/) do |name, start, finish, _, payload|
    Rails.logger.debug "#{name} #{payload} #{finish - start}"
  end
end

if Rails.env.production? || Rails.env.staging?
  udp_logger = ::LogStashLogger.new(port: 5228)
  parameter_filter = ActionDispatch::Http::ParameterFilter.new(Rails.application.config.filter_parameters)

  ActiveSupport::Notifications.subscribe(/process_action.action_controller|racing_on_rails/) do |name, start, finish, id, payload|
    payload[:status] = payload[:status].to_s if payload[:status] && payload[:status].is_a?(Integer)

    message = {
      current_person_name: ::Person.current.try(:name),
      current_person_id: ::Person.current.try(:id),
      duration: (finish - start),
      id: id,
      message: name,
      racing_association: RacingAssociation.current.short_name,
      start: start
    }.merge(parameter_filter.filter(payload))

    # Ideally, would traverse params and fix encodings
    begin
      udp_logger.info message
    rescue Encoding::UndefinedConversionError => e
      Rails.logger.debug "[#{Time.zone.now}] (#{e}) logging to Logstash #{message[:params]}"
      message.delete(:params)
      udp_logger.info message
    end
  end
end
