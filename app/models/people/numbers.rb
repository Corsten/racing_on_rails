# frozen_string_literal: true

module People
  module Numbers
    extend ActiveSupport::Concern

    included do
      has_many :race_numbers, -> { includes(:discipline, :number_issuer) }, dependent: :destroy

      accepts_nested_attributes_for :race_numbers,
                                    reject_if: proc { |attributes| !attributes.key?(:value) || attributes[:value].blank? }

      def self.find_all_by_number(number)
        RaceNumber
          .includes(:person)
          .where(year: [ RacingAssociation.current.year, RacingAssociation.current.next_year ])
          .where(value: number)
          .map(&:person)
      end
    end

    def number(discipline_param, reload = false, year = nil)
      return nil if discipline_param.nil?

      year ||= RacingAssociation.current.year
      if discipline_param.is_a?(Discipline)
        discipline_param = discipline_param.to_param
      end
      number = race_numbers(reload).detect do |race_number|
        race_number.year == year &&
          race_number.discipline_id == RaceNumber.discipline_id(discipline_param) &&
          race_number.number_issuer.name == RacingAssociation.current.short_name
      end
      number.try :value
    end

    # Look for RaceNumber +year+ in +attributes+. Not sure if there's a simple and better way to do that.
    def add_number(value, discipline, issuer = nil, number_year = year)
      return false if discipline.blank? && value.blank?

      mapped_discipline = if discipline.nil? || !discipline.numbers?
                            Discipline[:road]
                          else
                            discipline
                          end
      issuer = NumberIssuer.find_by(name: RacingAssociation.current.short_name) if issuer.nil?
      number_year ||= RacingAssociation.current.year

      if value.present?
        if new_record?
          build_number value, mapped_discipline, issuer, number_year
        else
          create_number value, mapped_discipline, issuer, number_year
        end
      else
        destroy_number discipline, issuer, number_year unless new_record?
      end
    end

    def build_number(value, discipline, issuer, year)
      unless race_number?(value, discipline, issuer, year)
        race_numbers.build(
          discipline: discipline,
          number_issuer: issuer,
          person: self,
          value: value,
          year: year
        )
      end
    end

    def create_number(value, discipline, issuer, year)
      unless race_number?(value, discipline, issuer, year)
        race_numbers.create(
          discipline: discipline,
          number_issuer: issuer,
          person: self,
          value: value,
          year: year
        )
      end
    end

    def destroy_number(discipline, issuer, year)
      RaceNumber.where(discipline: discipline, number_issuer: issuer, person: self, year: year).destroy_all
    end

    def race_number?(value, discipline, issuer, year)
      if new_record?
        race_numbers.any? do |n|
          n.value == value &&
            n.discipline == discipline &&
            n.number_issuer == issuer &&
            n.year == year
        end
      else
        RaceNumber.where(
          discipline: discipline,
          number_issuer: issuer,
          person: self,
          value: value,
          year: year
        ).exists?
      end
    end

    def bmx_number(reload = false, year = nil)
      number(Discipline[:bmx], reload, year)
    end

    def ccx_number(reload = false, year = nil)
      number(Discipline[:cyclocross], reload, year)
    end

    def dh_number(reload = false, year = nil)
      number(Discipline[:downhill], reload, year)
    end

    def road_number(reload = false, year = nil)
      number(Discipline[:road], reload, year)
    end

    def singlespeed_number(reload = false, year = nil)
      number(Discipline[:singlespeed], reload, year)
    end

    def track_number(reload = false, year = nil)
      number(Discipline[:track], reload, year)
    end

    def xc_number(reload = false, year = nil)
      number(Discipline[:mountain_bike], reload, year)
    end

    def bmx_number=(value)
      add_number(value, Discipline[:bmx])
    end

    def ccx_number=(value)
      add_number(value, Discipline[:cyclocross])
    end

    def dh_number=(value)
      add_number(value, Discipline[:downhill])
    end

    def road_number=(value)
      add_number(value, Discipline[:road])
    end

    def singlespeed_number=(value)
      add_number(value, Discipline[:singlespeed])
    end

    def track_number=(value)
      add_number(value, Discipline[:track])
    end

    def xc_number=(value)
      add_number(value, Discipline[:mountain_bike])
    end
  end
end
