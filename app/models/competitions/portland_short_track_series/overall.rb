module Competitions
  module PortlandShortTrackSeries
    class Overall < Competitions::Overall
      include PortlandShortTrackSeries::Common

      default_value_for :maximum_events, 7

      def after_calculate
        super
        MonthlyStandings.calculate! year
      end
    end
  end
end
