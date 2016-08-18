module Competitions
  class CrossCrusadeCallups < Competition
    default_value_for :name, "Cross Crusade Callups"

    def category_names
      [
        "Men A",
        "Men B",
        "Men C",
        "Athena",
        "Clydesdale",
        "Junior Men",
        "Junior Women",
        "Masters 35+ A",
        "Masters 35+ B",
        "Masters 35+ C",
        "Masters 50+",
        "Masters 60+",
        "Masters Women 35+ A",
        "Masters Women 35+ B",
        "Masters Women 45+",
        "Singlespeed Women",
        "Singlespeed",
        "Unicycle",
        "Women A",
        "Women B",
        "Women C"
      ]
    end

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

      if race.ages == (35..999) && race.ability_range == (1..1) && race.gender == "M"
        categories << "Masters Men A 40+"
      end

      if race.ages == (35..999) && race.ability_range == (2..2) && race.gender == "M"
        categories << "Masters Men B 40+"
      end

      if race.ages == (35..999) && race.ability_range == (3..3) && race.gender == "M"
        categories << "Masters Men C 40+"
        categories << "Men C 35+"
      end

      if race.equipment == "Unicycle"
        categories << "Stampede"
      end

      scope = super(race)
      categories.each do |category_name|
        category = Category.find_or_create_by(name: category_name)
        scope = scope.merge(Category.similar(category))
      end
    end

    def source_event_types
      [ SingleDayEvent, Event, Competitions::BlindDateAtTheDairyOverall ]
    end

    def after_source_results(results, race)
      results.each do |result|
        result["multiplier"] = 1
      end
    end
  end
end
