module Competitions
  class CrossCrusadeCallups < Competition
    include Competitions::CrossCrusade::Common

    default_value_for :name, "Cross Crusade Callups"

    def point_schedule
      [ 15, 12, 10, 8, 7, 6, 5, 4, 3, 2 ]
    end

    def source_events?
      true
    end

    def source_event_types
      [ SingleDayEvent, Event, Competitions::BlindDateAtTheDairyOverall ]
    end

    def after_source_results(results, race)
      results.each do |result|
        result["multiplier"] = 1
      end

      results.reject do |result|
        jr_cats = [ "Junior Men", "Junior Women", "Junior Men (12-18)", "Junior Women (12-18)" ]
        result["category_name"][/Junior/] && (!result["category_name"].in?(jr_cats))
      end
    end
  end
end
