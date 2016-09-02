module Competitions
  module Categories
    # Competition's races. Default to +category_names+ (e.g., Men A, Men B, …)
    # But some competitions have race names like "Team" or "Overall" drawn
    # from +source_result_category_names+.
    def race_category_names
      category_names
    end

    def source_result_categories
      categories = Category.where(name: source_result_category_names).all
      categories + categories.map(&:descendants).flatten
    end

    # Consider results from these categories. "Which results do we use?"
    # Distinct from "which categories does the competition have?"
    # In most cases, these are the same, but not always.
    def source_result_category_names
      category_names
    end

    def category_names
      [ friendly_name ]
    end

    # Only consider results from categories. Default to true.
    def categories?
      true
    end

    # Array of ids (integers)
    # +race+ category, +race+ category's siblings, and any competition categories
    def categories_for(race)
      [ race.category ] + race.category.descendants
    end

    def result_categories_by_race
      @result_categories_by_race ||= create_result_categories_by_race
    end

    def create_result_categories_by_race
      result_categories_by_race = Hash.new { |hash, race_category| hash[race_category] = [] }

      result_categories.each do |category|
         best_match = category.best_match_in(self)
         if best_match
           result_categories_by_race[best_match] << category
         end
       end

       debug_result_categories_by_race(result_categories_by_race) if logger.debug?

       result_categories_by_race
    end

    def result_categories
      Category.results_in_year(year).where("results.event_id" => source_events)
    end

    def after_source_results(results, race)
      results.each do |result|
        result["multiplier"] = result["points_factor"] || 1
      end
    end

    # Only members can score points?
    def members_only?
      false
    end


    private

    def debug_result_categories_by_race(result_categories_by_race)
      result_categories_by_race.each do |competition_category, source_results_categories|
        source_results_categories.sort_by(&:name).each do |category|
          logger.debug "result_categories_by_race for #{full_name} #{competition_category.name} #{category.name}"
        end
      end
    end
  end
end
