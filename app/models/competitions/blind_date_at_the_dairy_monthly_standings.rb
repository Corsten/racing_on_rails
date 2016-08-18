module Competitions
  class BlindDateAtTheDairyMonthlyStandings < Competition
    def self.parent_event_name
      "Blind Date at the Dairy"
    end

    def self.calculate!(year = Time.zone.today.year)
      ActiveSupport::Notifications.instrument "calculate.#{name}.competitions.racing_on_rails" do
        transaction do
          parent = ::WeeklySeries.year(year).where(name: parent_event_name).first

          if parent && parent.any_results_including_children?
            [ 9, 10 ].each do |month|
              month_name = Date::MONTHNAMES[month]
              standings = BlindDateAtTheDairyMonthlyStandings.find_or_create_by!(
                parent: parent,
                name: "#{month_name} Standings"
              )
              standings.date = Date.new(year, month)
              if standings.source_events.none?
                standings.add_source_events
              end
              standings.set_date
              standings.save!
              standings.delete_races
              standings.create_races
              standings.calculate!
            end
          end
        end
      end
      true
    end

    def category_names
      [
        "Beginner Men",
        "Beginner Women",
        "Junior Men 10-13",
        "Junior Men 14-18",
        "Junior Women 10-13",
        "Junior Women 14-18",
        "Masters Men A 40+",
        "Masters Men B 40+",
        "Masters Men C 40+",
        "Masters Men 50+",
        "Masters Men 60+",
        "Men A",
        "Men B",
        "Men C",
        "Singlespeed",
        "Stampede",
        "Women A",
        "Women B",
        "Women C"
      ]
    end

    def point_schedule
      [ 15, 12, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 ]
    end

    def add_source_events
      parent.children.select { |c| c.date.month == date.month }.each do |source_event|
        source_events << source_event
      end
    end

    # Only members can score points?
    def members_only?
      false
    end

    def default_bar_points
      1
    end

    def source_events?
      true
    end
  end
end
