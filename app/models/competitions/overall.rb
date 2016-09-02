module Competitions
  # Common superclass for Omniums and Series standings.
  class Overall < Competition
   validates_presence_of :parent
   after_create :add_source_events

   def self.parent_event_name
     self.name
   end

    def self.calculate!(year = Time.zone.today.year)
      ActiveSupport::Notifications.instrument "calculate.#{name}.competitions.racing_on_rails" do
        transaction do
          parent = ::MultiDayEvent.year(year).where(name: parent_event_name).first

          overall = parent.try(:overall)
          if parent && parent.any_results_including_children?
            if !overall
              # parent.create_overall will create an instance of Overall, which is probably not what we want
              overall = self.create!(parent_id: parent.id, date: parent.date)
              parent.overall = overall
            end
            overall.set_date
            overall.delete_races
            overall.create_races
            overall.calculate!
          end
        end
      end
      true
    end

    def default_name
      "Series Overall"
    end

    def source_events?
      true
    end

    def categories_for(race)
      result_categories_by_race[race.category]
    end
  end
end
