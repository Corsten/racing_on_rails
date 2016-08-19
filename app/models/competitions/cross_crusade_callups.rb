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

    def members_only?
      false
    end

    def categories_scope(race)
      categories = []

      if year < 2016
        if race.name == "Masters 35+ A"
          categories << "Masters Men A 40+"
        end
        if race.name == "Masters 35+ B"
          categories << "Masters Men B 40+"
        end
        if race.name == "Masters 35+ C"
          categories << "Masters Men C 40+"
          categories << "Men C 35+"
        end
        if race.name == "Masters 50+"
          categories << "Men 50+"
          categories << "Masters Men 50+"
          categories << "Masters 50+"
        end
        if race.name == "Masters 60+"
          categories << "Men 60+"
          categories << "Masters Men 60+"
          categories << "Masters 60+"
        end
        if race.name == "Masters Women 45+"
          categories << "Women 45+"
        end
        if race.name == "Unicycle"
          categories << "Stampede"
        end
      else
        if race.name == "Masters 35+ 1/2"
          categories << "Masters Men 1/2 40+"
        end
        if race.name == "Masters 35+ 3"
          categories << "Masters Men 3 40+"
        end
        if race.name == "Masters 35+ 4"
          categories << "Masters Men 4 40+"
          categories << "Men 4 35+"
        end
        if race.name == "Masters 50+"
          categories << "Men 50+"
          categories << "Masters Men 50+"
          categories << "Masters 50+"
        end
        if race.name == "Masters 60+"
          categories << "Men 60+"
          categories << "Masters Men 60+"
          categories << "Masters 60+"
        end
        if race.name == "Masters Women 45+"
          categories << "Women 45+"
        end
        if race.name == "Unicycle"
          categories << "Stampede"
        end
      end

      scope = super(race)
      categories.each do |category_name|
        category = Categor.where(name: category_name).find_or_create!
        scope = scope.merge(Category.samw(category))
      end
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
