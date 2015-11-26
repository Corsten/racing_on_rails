module Competitions
  class OregonWomensPrestigeSeries < Competition
    include Competitions::OregonWomensPrestigeSeriesModules::Common

    default_value_for :categories, true
    default_value_for :category_names, [ "Women 1/2/3", "Women 4" ]

    # Decreasing points to 20th place, then 2 points for 21st through 100th
    default_value_for :point_schedule, [ 100, 80, 70, 60, 55, 50, 45, 40, 35, 30, 25, 20, 18, 16, 14, 12, 10, 8, 6, 4 ] + ([ 2 ] * 80)
    default_value_for :source_event_types, [ MultiDayEvent, SingleDayEvent, Event ]

    def source_events?
      true
    end

    def source_event_ids(race)
      if women_4?(race)
        source_events.map(&:id) - cat_123_only_event_ids
      else
        source_events.map(&:id)
      end
    end

    def source_results_query(race)
      # Only consider results with categories that match +race+'s category
      if categories?
        super.where("races.category_id" => categories_for(race))
      else
        super
      end
    end

    def after_source_results(results, race)
      # Ignore BAR points multiplier. Leave query "universal".
      set_multiplier results
      results
    end


    private

    def women_4?(race)
      race.category.name == "Women 4"
    end
  end
end
