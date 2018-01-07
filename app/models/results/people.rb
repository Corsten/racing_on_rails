# frozen_string_literal: true

module Results
  module People
    extend ActiveSupport::Concern

    included do
      after_save :update_person_number
      after_destroy :destroy_people

      belongs_to :person

      scope :person, lambda { |person|
        person_id = if person.is_a? Person
                      person.id
                    else
                      person
                    end

        includes(:team, :person, :scores, :category, race: %i[event category])
          .where(person_id: person_id)
      }
    end

    def set_person
      if person&.new_record?
        person.updated_by = event
        if person.name.blank?
          self.person = nil
        else
          existing_people = find_people
          if existing_people.size == 1
            self.person = existing_people.first
            ActiveSupport::Notifications.instrument "single_match.set_person.results.racing_on_rails", place: place, event_id: event_id, race_id: race_id, name: person_name
          elsif existing_people.size > 1
            self.person = Person.select_by_recent_activity(existing_people)
            ActiveSupport::Notifications.instrument "select_by_recent_activity.set_person.results.racing_on_rails", id: id, name: person_name
          end
        end
      end
    end

    # Use +first_name+, +last_name+, +race_number+, +team+ to figure out if +person+ already exists.
    # Returns an Array of People if there is more than one potential match
    #
    # Need Event to match on race number. Event will not be set before result is saved to database
    def find_people
      matches = Set.new

      matches = eager_find_person_by_license(matches)
      ActiveSupport::Notifications.instrument "eager_find_person_by_license.set_person.results.racing_on_rails", place: place, event_id: event_id, race_id: race_id, name: person_name, count: matches.size, license: license
      return matches if matches.size == 1

      matches = find_person_by_name(matches)
      ActiveSupport::Notifications.instrument "find_person_by_name.set_person.results.racing_on_rails", place: place, event_id: event_id, race_id: race_id, name: person_name, count: matches.size
      return matches if matches.size == 1

      matches = find_person_by_number(matches)
      ActiveSupport::Notifications.instrument "find_person_by_number.set_person.results.racing_on_rails", place: place, event_id: event_id, race_id: race_id, name: person_name, count: matches.size, number: number
      return matches if matches.size == 1

      matches = find_person_by_team_name(matches)
      ActiveSupport::Notifications.instrument "find_person_by_team_name.set_person.results.racing_on_rails", place: place, event_id: event_id, race_id: race_id, name: person_name, count: matches.size, team_name: team_name
      return matches if matches.size == 1

      matches = find_person_by_license(matches)
      ActiveSupport::Notifications.instrument "find_person_by_license.set_person.results.racing_on_rails", place: place, event_id: event_id, race_id: race_id, name: person_name, count: matches.size, license: license
      matches
    end

    # license first if present and source is reliable (USAC)
    def eager_find_person_by_license(matches)
      if RacingAssociation.current.eager_match_on_license? && license.present?
        person = Person.where(license: license).first
        matches << person if person
      end

      matches
    end

    def find_person_by_name(matches)
      matches + Person.find_all_by_name_or_alias(first_name: first_name, last_name: last_name)
    end

    def find_person_by_number(matches)
      if number.present?
        if matches.size > 1
          # use number to choose between same names
          RaceNumber.find_all_by_value_and_event(number, event).each do |race_number|
            matches = Set.new [race_number.person] if matches.include?(race_number.person)
          end
        elsif name.blank?
          # no name, so try to match by number
          matches = RaceNumber.find_all_by_value_and_event(number, event).map(&:person)
        end
      end

      matches
    end

    def find_person_by_team_name(matches)
      return matches if team_name.blank?

      team = Team.find_by_name_or_alias(team_name)
      return matches unless team

      team_name_matches = matches.select { |m| m.team_id == team.id }

      if team_name_matches.empty?
        # None of the potential matches are on the result's team:
        # don't reject anyone
        matches
      else
        team_name_matches
      end
    end

    # Licenses *should* be uniq but this hasn't been enforced in the DB
    def find_person_by_license(matches)
      return matches if license.blank?

      license_matches = matches.select { |m| m.license == license }

      if license_matches.empty?
        matches
      else
        license_matches
      end
    end

    def update_membership
      if update_membership?
        person.updated_by = event
        person.member_from = race.date
      end
    end

    def update_membership?
      person &&
        RacingAssociation.current.add_members_from_results? &&
        person.new_record? &&
        person.first_name.present? &&
        person.last_name.present? &&
        person[:member_from].blank? &&
        event.association? &&
        !rental_number?
    end

    # Set +person#number+ to +number+ if this isn't a rental number
    def update_person_number
      return true if competition_result?

      if person &&
         event.number_issuer &&
         event.number_issuer != RacingAssociation.current.number_issuer &&
         number.present? &&
         !rental_number?

        person.updated_by = updated_by
        person.add_number number, Discipline[event.discipline], event.number_issuer, event.date.year
      end
    end

    # Destroy People that only exist because they were created by importing results
    def destroy_people
      person.destroy if person&.results&.count == 0 && person.created_from_result? && !person.updated_after_created?
    end

    # Only used for manual entry of Cat 4 Womens Series Results
    def validate_person_name
      errors.add(:first_name, "and last name cannot both be blank") if first_name.blank? && last_name.blank?
    end

    def first_name=(value)
      if person
        person.first_name = value
      else
        self.person = Person.new(first_name: value)
      end
      self[:first_name] = value
      self[:name] = person.try(:name, date)
    end

    def last_name=(value)
      if person
        person.last_name = value
      else
        self.person = Person.new(last_name: value)
      end
      self[:last_name] = value
      self[:name] = person.try(:name, date)
    end

    def person_name
      name
    end

    # person.name
    def name=(value)
      if value.present?
        self.person = Person.new(name: value) if person.try(:name) != value
        self[:first_name] = person.first_name
        self[:last_name] = person.last_name
      else
        self.person = nil
        self[:first_name] = nil
        self[:last_name] = nil
      end
      self[:name] = value
    end

    def person_name=(value)
      self.name = value
    end
  end
end
