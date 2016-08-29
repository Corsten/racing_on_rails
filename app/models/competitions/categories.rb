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

    # Only consider results from categories. Default to true: use all races in year.
    def categories?
      true
    end

    # Array of ids (integers)
    # +race+ category, +race+ category's siblings, and any competition categories
    def categories_for(race)
      category_mappings(race.event)[race.category]
    end

    # TODO split out caching
    # TODO maybe rename
    def category_mappings(event)
      return @category_mappings if @category_mappings

      @category_mappings = Hash.new { |hash, race_category| hash[race_category] = [] }

      categories_with_results_in_year = Category.joins(races: :results).where("results.year" => year).uniq
      categories_with_results_in_year.each do |category|
         best_match = category.best_match_in(event)
         if best_match
           @category_mappings[best_match] << category
         end
       end

       debug_category_mappings if logger.debug?

       @category_mappings
    end


    private

    def debug_category_mappings
      @category_mappings.each do |competition_category, source_results_categories|
        source_results_categories.sort_by(&:name).each do |category|
          logger.debug "category_mappings for #{full_name} #{competition_category.name} #{category.name}"
        end
      end
    end
  end
end
