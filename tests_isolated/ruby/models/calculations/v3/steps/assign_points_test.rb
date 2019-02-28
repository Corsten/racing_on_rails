# frozen_string_literal: true

require_relative "../../v3"

module Calculations
  module V3
    module Steps
      # :stopdoc:
      class AssignPointsTest < Ruby::TestCase
        def test_assign_points
          category = Models::Category.new("Masters Men")
          rules = Rules.new(
            categories: [category],
            points_for_place: [100, 75, 50, 20, 10]
          )
          calculator = Calculator.new(rules: rules, source_results: [])
          event_category = calculator.event_categories.first

          source_result = Models::SourceResult.new(id: 33, event_category: Models::EventCategory.new(category), place: 1)
          participant = Models::Participant.new(0)
          result = Models::CalculatedResult.new(participant, [source_result])
          event_category.results << result

          source_result = Models::SourceResult.new(id: 19, event_category: Models::EventCategory.new(category), place: 2)
          participant = Models::Participant.new(1)
          result = Models::CalculatedResult.new(participant, [source_result])
          event_category.results << result

          event_categories = AssignPoints.calculate!(calculator)

          assert_equal 100, event_categories.first.results[0].source_results.first.points
          assert_equal 75, event_categories.first.results[1].source_results.first.points
        end

        def test_double_points_for_last_event
          category = Models::Category.new("Women 4")
          rules = Rules.new(
            categories: [category],
            double_points_for_last_event: true,
            end_date: Date.new(2018, 5, 8),
            points_for_place: [100, 75, 50, 20, 10]
          )
          calculator = Calculator.new(rules: rules, source_results: [])
          calculation_event_category = calculator.event_categories.first

          event_category = Models::EventCategory.new(category)
          source_result = Models::SourceResult.new(id: 33, date: Date.new(2018, 5, 1), event_category: event_category, place: 1)
          participant = Models::Participant.new(0)
          result = Models::CalculatedResult.new(participant, [source_result])
          calculation_event_category.results << result

          event_category = Models::EventCategory.new(category)
          source_result = Models::SourceResult.new(id: 19, date: Date.new(2018, 5, 8), event_category: event_category, place: 2)
          result = Models::CalculatedResult.new(participant, [source_result])
          calculation_event_category.results << result

          event_categories = AssignPoints.calculate!(calculator)

          assert_equal 100, event_categories.first.results[0].source_results.first.points
          assert_equal 150, event_categories.first.results[1].source_results.first.points
        end

        def test_skip_rejcted_categoeies
          category = Models::Category.new("Masters Men")
          rules = Rules.new(
            categories: [category],
            points_for_place: [100, 75, 50, 20, 10]
          )
          calculator = Calculator.new(rules: rules, source_results: [])
          event_category = calculator.event_categories.first

          source_result = Models::SourceResult.new(id: 33, event_category: Models::EventCategory.new(category), place: 1)
          participant = Models::Participant.new(0)
          result = Models::CalculatedResult.new(participant, [source_result])
          event_category.results << result

          event_category.reject("nope")
          event_categories = AssignPoints.calculate!(calculator)

          assert_equal 0, event_categories.first.results[0].source_results.first.points
        end
      end
    end
  end
end
