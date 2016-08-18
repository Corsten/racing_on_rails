module Competitions
  # See Bar class.
  class OverallBar < Competition
    include OverallBars::Categories
    # include OverallBars::Points
    include OverallBars::Races

    def create_children
      Discipline
        .find_all_bar
        .reject { |discipline| [Discipline[:age_graded], Discipline[:overall], Discipline[:team]].include?(discipline) }
        .reject { |discipline| Bar.year(year).where(discipline: discipline.name).exists? }
        .each { |discipline| create_child discipline }
    end

    def create_child(discipline)
      Bar.create!(
        parent: self,
        name: "#{year} #{discipline.name} BAR",
        date: date,
        discipline: discipline.name
      )
    end

    def source_results_query(race)
      super
        .where(
          "(events.discipline not in (:disciplines) and races.category_id in (:categories))
          or (events.discipline in (:disciplines) and races.category_id in (:mtb_categories))",
          disciplines: Discipline["Mountain Bike"].names,
          mtb_categories: mtb_categories_for(race)
        )
    end

    # Array of ids (integers)
    # +race+ category, +race+ category's siblings, and any competition categories
    # Overall BAR does some awesome mappings for MTB and DH
    def mtb_categories_for(race)
      return [] unless race.category

      case race.category.name
      when "Senior Men"
        [
          ::Category.find_or_create_by(name: "Pro Men"),
          ::Category.find_or_create_by(name: "Elite Men"),
          ::Category.find_or_create_by(name: "Category 1 Men")
        ]
      when "Senior Women"
        [
          ::Category.find_or_create_by(name: "Pro Women"),
          ::Category.find_or_create_by(name: "Elite Women"),
          ::Category.find_or_create_by(name: "Category 1 Women")
        ]
      when "Category 3 Men"
        [ ::Category.find_or_create_by(name: "Category 2 Men") ]
      when "Category 3 Women"
        [ ::Category.find_or_create_by(name: "Category 2 Women") ]
      when "Category 4/5 Men"
        [ ::Category.find_or_create_by(name: "Category 3 Men") ]
      when "Category 4 Women"
        [ ::Category.find_or_create_by(name: "Category 3 Women") ]
      else
        [ race.category ]
      end
    end

    def category_names
      [
        "Clydesdale",
        "Category 3 Men",
        "Category 3 Women",
        "Category 4 Women",
        "Category 4/5 Men",
        "Junior Men",
        "Junior Women",
        "Masters Men 4/5",
        "Masters Men 1/2/3",
        "Masters Women 4",
        "Masters Women 1/2/3",
        "Category 1/2 Men",
        "Category 1/2 Women",
        "Singlespeed/Fixed",
        "Tandem"
      ]
    end

    def source_event_types
      [ Competitions::Bar ]
    end

    def after_source_results(results, _)
      results = reject_duplicate_discipline_results(results)
      # BAR Results with the same place are always ties, and never team results
      set_team_size_to_one results
    end

    # If person scored in more than one category that maps to same overall category in a discipline,
    # count only highest-placing category.
    # This typically happens for age-based categories like Masters and Juniors
    # Assume scores sorted in preferred order (usually by points descending)
    # For the Category 4/5 Overall BAR, if a person has both a Cat 4 and Cat 5 result for the same discipline,
    # we only count the Cat 4 result
    def reject_duplicate_discipline_results(source_results)
      filtered_results = []

      source_results.group_by { |r| r["participant_id"] }.each do |_, results|
        results.select { |r| r["category_name"] == "Category 4 Men" }.each do |cat_4_result|
          results = results.reject do |r|
            r["category_name"] == "Category 5 Men" && r["discipline"] == cat_4_result["discipline"]
          end
        end

        results.group_by { |r| r["discipline"] }.each do |_, discipline_results|
          filtered_results << discipline_results.sort_by { |r| r["points"].to_f }.reverse.first
        end
      end

      filtered_results
    end

    # 300 points for first place, 299 for second, etc.
    def point_schedule
      (1..300).to_a.reverse
    end

    def maximum_events(_)
      5
    end

    def friendly_name
      'Overall BAR'
    end

    def default_discipline
      "Overall"
    end
  end
end
