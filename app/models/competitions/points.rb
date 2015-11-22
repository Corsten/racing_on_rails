module Competitions
  module Points
    extend ActiveSupport::Concern

    def point_schedule
      @point_schedule || nil
    end

    def point_schedule=(value)
      @point_schedule = value
    end
  end
end
