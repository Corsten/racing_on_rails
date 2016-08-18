module Competitions
  class OregonWomensPrestigeSeries < Competition
    include Competitions::OregonWomensPrestigeSeriesModules::Common

    def friendly_name
      "Oregon Womens Prestige Series"
    end

    def category_names
      [ "Women 1/2", "Women 3", "Women 4/5" ]
    end

    def source_events?
      true
    end

    def maximum_events(race)
      5
    end

    def source_event_types
      [ MultiDayEvent, SingleDayEvent, Event ]
    end

    def source_event_ids(race)
      if women_4_5?(race)
        source_events.map(&:id) - cat_123_only_event_ids
      else
        source_events.map(&:id)
      end
    end

    def after_source_results(results, race)
      # Ignore BAR points multiplier. Leave query "universal".
      set_multiplier results
      results
    end


    private

    def women_4_5?(race)
      race.category.ability_range == (4..5)
    end
  end
end
