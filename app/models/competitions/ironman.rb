module Competitions
  # Who has done the most events? Just counts starts/appearences in results. Not pefect -- some events
  # are probably over-counted.
  class Ironman < Competition
    default_value_for :break_ties, false
    default_value_for :dnf_points, 1
    default_value_for :notes, "The Ironman Competition is a 'just for fun' record of the number of events riders do. There is no prize just identification of riders who need to get a life."

    def points_for(source_result)
      1
    end

    def source_results_query(race)
      super.where("events.ironman" => true)
    end
  end
end
