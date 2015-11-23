module Competitions
  module Points
    extend ActiveSupport::Concern

    included do
      serialize :place_bonus
      default_value_for :place_bonus, nil
    end


    def default_bar_points
      0
    end

    def point_schedule
      @point_schedule || nil
    end

    def point_schedule=(value)
      @point_schedule = value
    end
  end
end
