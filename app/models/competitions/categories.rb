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

    def categories_scope(race)
      if exact_categories?
        Category.same race.category
      else
        Category.within race
      end
    end

    # Count results only if abilities match exactly.
    # If +true+, Senior Men would count: Senior Men, Category 1/2, Category 3, Category 4
    # If +false+, Senior Men would only count: Senior Men
    def exact_categories?
      false
    end

    # Array of ids (integers)
    # +race+ category, +race+ category's siblings, and any competition categories
    def categories_for(race)
      [ race.category ] + race.category.descendants
    end
  end
end
