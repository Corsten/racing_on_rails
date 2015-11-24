module Competitions
  module OregonWomensPrestigeSeriesModules
    module Common
      def set_multiplier(results)
        results.each do |result|
          if result["type"] == "MultiDayEvent"
            result["multiplier"] = 1.5
          else
            result["multiplier"] = 1
          end
        end
      end

      def cat_123_only_event_ids
        [ 21334, 21148, 21393, 21146, 21186 ]
      end
    end
  end
end
