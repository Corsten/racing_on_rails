module Competitions
  # Mount Tabor Overall Series results
  class TaborOverall < Overall
    default_value_for :double_points_for_last_event?, true
    default_value_for :default_bar_points, 1

    def self.parent_event_name
      "Mt. Tabor Series"
    end

    def category_names
      [
        "Category 3 Men",
        "Category 4 Men",
        "Category 4 Women",
        "Category 5 Men",
        "Masters Men 50+",
        "Masters Men 40+",
        "Masters Women",
        "Senior Men",
        "Senior Women"
      ]
    end

    def point_schedule
      [ 100, 70, 50, 40, 36, 32, 28, 24, 20, 16, 15, 14, 13, 12, 11 ]
    end
  end
end
