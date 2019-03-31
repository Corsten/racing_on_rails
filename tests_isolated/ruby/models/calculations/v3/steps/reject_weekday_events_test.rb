# frozen_string_literal: true

require_relative "../../v3"

module Calculations
  module V3
    module Steps
      # :stopdoc:
      class RejectWeekdayEventsTest < Ruby::TestCase
        def test_calculate
          category = Models::Category.new("Women")
          rules = Rules.new(
            category_rules: [Models::CategoryRule.new(category)],
            weekday_events: false
          )
          calculator = Calculator.new(rules: rules, source_results: [])

          participant = Models::Participant.new(0)
          source_results = []

          event = Models::Event.new(id: 0, calculated: true, date: Date.new(2019, 3, 23))
          source_results << Models::SourceResult.new(
            id: 0,
            event_category: Models::EventCategory.new(category, event),
            participant: participant,
            place: 1,
            points: 100
          )

          event = Models::Event.new(id: 1, calculated: true, date: Date.new(2019, 3, 28))
          source_results << Models::SourceResult.new(
            id: 1,
            event_category: Models::EventCategory.new(category, event),
            participant: participant,
            place: 2,
            points: 50
          )

          result = Models::CalculatedResult.new(participant, source_results)
          event_category = calculator.event_categories.first.results << result

          event_categories = RejectWeekdayEvents.calculate!(calculator)

          source_results = event_categories.first.results.first.source_results.sort_by(&:id)

          refute source_results.first.rejected?

          assert source_results.last.rejected?
          assert_equal :weekday, source_results.last.rejection_reason
        end
      end
    end
  end
end
