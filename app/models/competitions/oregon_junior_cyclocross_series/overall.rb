module Competitions
  module OregonJuniorCyclocrossSeries
    class Overall < Competition
      default_value_for :members_only, false
      default_value_for :maximum_events, 4
      default_value_for :point_schedule, [ 30, 28, 26, 24, 22, 20, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 ]

      def friendly_name
        "Oregon Junior Cyclocross Series"
      end

      def source_events?
        true
      end

      def category_names
        [
          "Junior Men 10-12",
          "Junior Men 13-14",
          "Junior Men 15-16",
          "Junior Men 17-18",
          "Junior Women 10-12",
          "Junior Women 13-14",
          "Junior Women 15-16",
          "Junior Women 17-18"
        ]
      end

      def source_results_query(race)
        super.
        where("races.category_id" => categories_for(race))
      end

      def create_slug
        "ojcs"
      end
    end
  end
end
