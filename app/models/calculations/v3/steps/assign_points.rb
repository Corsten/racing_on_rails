# frozen_string_literal: true

module Calculations
  module V3
    module Steps
      module AssignPoints
        def self.calculate!(calculator)
          calculator.event_categories.reject(&:rejected?).each do |category|
            category.unrejected_results.each do |result|
              result.unrejected_source_results.each_with_index do |source_result, index|
                source_result.points = points_for_place(source_result, calculator.rules.points_for_place, calculator.rules.place_by, category.unrejected_results.size, index) *
                                       last_event_multiplier(source_result, calculator.rules) *
                                       multiplier(source_result)
              end
            end
          end

          calculator.event_categories
        end

        # TODO fix number of args
        def self.points_for_place(source_result, points_for_place, place_by, results_size, index)
          return 0 unless source_result.placed?

          if place_by == "place"
            return 100.0 * (results_size - index) / results_size
          end

          return 1 unless points_for_place

          points_for_place[source_result.numeric_place - 1] || 0
        end

        def self.last_event_multiplier(source_result, rules)
          if rules.double_points_for_last_event? && last_event?(source_result)
            2
          else
            1
          end
        end

        def self.last_event?(source_result)
          raise(ArgumentError, "source_result.date required to check for last event") unless source_result.date
          raise(ArgumentError, "source_result.parent_end_date required to check for last event") unless source_result.parent_end_date

          # Only one event in series
          return if source_result.date == source_result.parent_date

          source_result.date == source_result.parent_end_date
        end

        def self.multiplier(source_result)
          raise(ArgumentError, "event required to assign points") unless source_result.event

          source_result.event.multiplier.to_f
        end
      end
    end
  end
end
