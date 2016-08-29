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
        result["category_id"].in?(cat_4_category_ids) && result["event_id"].in?(cat_123_only_event_ids)
      end

      # Ignore BAR points multiplier. Leave query "universal".
      set_multiplier results
      results
    end

    def cat_4_category_ids
      if @cat_4_category_ids.nil?
        categories = Category.where(name: "Category 4 Women")
        @cat_4_category_ids = categories.map(&:id) + categories.map(&:descendants).to_a.flatten.map(&:id)
      end
      @cat_4_category_ids
    end
  end
end
