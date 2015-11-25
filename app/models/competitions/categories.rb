module Competitions
  module Categories
    extend ActiveSupport::Concern

    included do
      serialize :category_names
      default_value_for(:category_names) { |r| [ r.default_name ] }
    end

    # Competition's races. Default to +category_names+ (e.g., Men A, Men B, …)
    # But some competitions have race names like "Team" or "Overall" drawn
    # from +source_result_category_names+.
    def race_category_names
      category_names
    end

    def race_category_names_string
      race_category_names.join("\n")
    end

    def race_category_names_string=(value)
      if value.present?
        self.race_category_names = value.split.reject(&:blank?)
      else
        self.race_category_names = []
      end
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

    def source_result_category_names_string
      source_result_category_names.join("\n")
    end

    def source_result_category_names_string=(value)
      if value.present?
        self.source_result_category_names = value.split.reject(&:blank?)
      else
        self.source_result_category_names = []
      end
    end

    def category_names_string
      category_names.join("\n")
    end

    def category_names_string=(value)
      if value.present?
        self.category_names = value.split.reject(&:blank?)
      else
        self.category_names = []
      end
    end

    # Array of ids (integers)
    # +race+ category, +race+ category's siblings, and any competition categories
    def categories_for(race)
      [ race.category ] + race.category.descendants
    end
  end
end
