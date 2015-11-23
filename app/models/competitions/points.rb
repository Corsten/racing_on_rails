module Competitions
  module Points
    extend ActiveSupport::Concern

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
