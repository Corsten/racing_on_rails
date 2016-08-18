module Competitions
  class OregonWomensPrestigeTeamSeries < Competition
    include Competitions::OregonWomensPrestigeSeriesModules::Common

    def friendly_name
      "Oregon Womens Prestige Team Series"
    end

    def category_names
      [ "Team" ]
    end

    def source_events?
      true
    end

    def source_events
      (OregonWomensPrestigeSeries.find_for_year(year) || OregonWomensPrestigeSeries.create).source_events
    end

    def results_per_race
      3
    end

    def team?
      true
    end

    def maximum_events(race)
      5
    end

    def after_source_results(results, race)
      results = results.reject do |result|
        result["category_ability"] == 4 && result["event_id"].in?(cat_123_only_event_ids)
      end

      # Ignore BAR points multiplier. Leave query "universal".
      set_multiplier results
      results
    end

    def categories_for(race)
      if OregonWomensPrestigeSeries.find_for_year
        categories = Category.where(name: OregonWomensPrestigeSeries.find_for_year.category_names)
        categories = categories + categories.map(&:descendants).to_a.flatten
      else
        []
      end
    end
  end
end
