module Competitions
  module OverallBars
    module Races
      extend ActiveSupport::Concern

      def find_race(discipline, category)
        if Discipline[:overall] == discipline
          event = self
        else
          event = children.detect { |e| e.discipline == discipline.name }
        end

        ::Race.
          where(event_id: event.id).
          where(category_id: category.id).
          includes(:results).
          first
      end

      def create_races
        [ 'Senior Men', 'Category 3 Men', 'Category 4/5 Men',
          'Senior Women', 'Category 3 Women', 'Category 4 Women',
          'Junior Men', 'Junior Women', 'Masters Men', 'Masters Women',
          'Masters Men 4/5', 'Masters Women 4',
          'Singlespeed/Fixed', 'Tandem', "Clydesdale" ].each do |category_name|
          races.create category: ::Category.find_or_create_by(name: category_name)
        end
      end
    end
  end
end