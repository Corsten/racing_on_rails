# TODO Delete
module Competitions
  module OverallBars
    module Categories
      extend ActiveSupport::Concern

      def equivalent_category_for(category_friendly_param, discipline)
        return nil unless category_friendly_param && discipline

        if discipline == Discipline[:overall]
          event = self
        else
          event = children.detect { |child| child.discipline == discipline.name }
          return unless event
        end

        category = event.categories.detect { |cat| cat.friendly_param == category_friendly_param }

        if category.nil?
          event.categories.detect { |cat| cat.friendly_param == category_friendly_param || cat.parent.friendly_param == category_friendly_param } ||
            event.categories.sort.first
        else
          category
        end
      end

      def find_category(name)
        ::Category.find_by_name name
      end
    end
  end
end
