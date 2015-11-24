module Competitions
  module Points
    extend ActiveSupport::Concern

    included do
      serialize :place_bonus
      serialize :point_schedule
      default_value_for :place_bonus, nil
      default_value_for :point_schedule, nil
    end

    def default_bar_points
      0
    end
  end
end
