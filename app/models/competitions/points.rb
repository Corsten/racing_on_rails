module Competitions
  module Points
    extend ActiveSupport::Concern

    included do
      serialize :place_bonus
      serialize :point_schedule
      default_value_for :place_bonus, nil
      default_value_for :point_schedule, nil
    end

    def place_bonus_string
      if place_bonus.present?
        place_bonus.join(", ")
      else
        ""
      end
    end

    def place_bonus_string=(value)
      if value.present?
        self.place_bonus = value.split(",").map(&:to_f)
      else
        self.place_bonus = nil
      end
    end

    def point_schedule_string
      if point_schedule.present?
        point_schedule.join(", ")
      else
        ""
      end
    end

    def point_schedule_string=(value)
      if value.present?
        self.point_schedule = value.split(",").map(&:to_f)
      else
        self.point_schedule = nil
      end
    end

    def default_bar_points
      0
    end
  end
end
