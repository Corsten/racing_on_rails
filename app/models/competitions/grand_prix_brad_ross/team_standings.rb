module Competitions
  module GrandPrixBradRoss
    class TeamStandings < Competition
      include GrandPrixBradRoss::Common

      validates_presence_of :parent
      after_create :add_source_events
      before_create :set_name

      def self.calculate!(year = Time.zone.today.year)
        ActiveSupport::Notifications.instrument "calculate.#{name}.competitions.racing_on_rails" do
          transaction do
            series = Series.where(name: parent_event_name).year(year).first

            if series && series.any_results_including_children?
              team_competition = series.child_competitions.detect { |c| c.is_a? TeamStandings }
              unless team_competition
                team_competition = self.new(parent_id: series.id)
                team_competition.save!
              end
              team_competition.set_date
              team_competition.delete_races
              team_competition.create_races
              team_competition.calculate!
            end
          end
        end
        true
      end

      def set_name
        self.name = "Team Competition"
      end

      def race_category_names
        [ "Team" ]
      end

      def team?
        true
      end

      def members_only?
        false
      end

      def source_events?
        true
      end

      def use_source_result_points?
        true
      end

      def results_per_event
        6
      end

      def results_per_race
        Competition::UNLIMITED
      end

      # Unique reshuffling of results for this competition before calculation
      # Group by event and apply all below:
      # Group results into categories based on participant age and source result gender
      # - M/F: 10-14, 15-18, 19-34, 35-44, 45-54, 55+
      # - infer age from category if there is no participant age
      # Sort by ability category, then by place
      # reject bottom 10% from each category except the "lowest" (Cat 3s)
      # assign points from 0-100 by 100 * ( n - p + 1 ) / n where n = age/gender category size and p = place
      def after_source_results(results, race)
        source_event_ids(race).map do |event_id|
          _results = results.select { |r| r["event_id"] == event_id }
          _results = _results.select { |r| r["place"].to_i > 0 }
          _results = group_results_by_team_standings_categories(_results)

          _results.each do |category, category_results|
            _category_results = sort_by_ability_and_place(category_results)
            _category_results = reject_worst_results(_category_results)
            _category_results = add_points(category, _category_results)
            _results[category] = _category_results
          end

          _results.values.flatten
        end.
        flatten
      end

      def group_results_by_team_standings_categories(results)
        grouped_results = Hash.new { |h, k| h[k] = [] }

        results.each do |result|
          grouped_results[team_standings_category_for(result)] << result
        end

        grouped_results
      end

      def team_standings_category_for(result)
        ages_begin = result["age"]
        ages_end = result["age"]

        team_standings_categories.detect do |category|
          if category.name.in?([ "Clydesdale", "Singlespeed", "Singlespeed Men", "Singlespeed Women" ])
            if category.name == result["category_name"]
              return category
            else
              next
            end
          end

          category.ages_begin <= ages_begin &&
          category.ages_end   >= ages_end &&
          category.gender     == result["category_gender"]
        end
      end

      def team_standings_categories
        @team_standings_categories ||= find_or_create_team_standings_categories
      end

      def find_or_create_team_standings_categories
        [
          Category.find_or_create_by_normalized_name("Athena"),
          Category.find_or_create_by_normalized_name("Clydesdale"),
          Category.find_or_create_by_normalized_name("Singlespeed Men"),
          Category.find_or_create_by_normalized_name("Singlespeed Women")
        ] +
        %w{ Men Women }.map do |gender|
          [ "10-18", "19-34", "35-49", "50+" ].map do |ages|
            Category.find_or_create_by_normalized_name("#{gender} #{ages}")
          end
        end.
        flatten
      end

      def sort_by_ability_and_place(results)
        results.sort do |x, y|
          diff = x["category_ability"] <=> y["category_ability"]

          if diff == 0
            numeric_place(x) <=> numeric_place(y)
          else
            diff
          end
        end
      end

      # Similar methods work on object attributes, not hash values
      def numeric_place(result)
        if result["place"] && result["place"].to_i > 0
          result["place"].to_i
        else
          Float::INFINITY
        end
      end

      def reject_worst_results(results)
        results.
        group_by { |r| r["category_ability"] }.
        map do |category_ability, category_results|
          if category_ability < 3
            category_results[ 0, (category_results.size * 0.9).ceil ]
          else
            category_results
          end
        end.
        flatten
      end

      def add_points(category, results)
        results.map.with_index do |result, index|
          place = index + 1
          result["points"] = 100.0 * ((results.size - place) + 1) / results.size
          result["notes"] = "#{place}/#{results.size} in #{category.name}"
          result
        end
      end
    end
  end
end
