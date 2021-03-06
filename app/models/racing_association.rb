# frozen_string_literal: true

# OBRA, WSBA, USA Cycling, etc …
# Many defaults. Override in environment.rb. Stored in RacingAssociation.current constant.
# bar_point_schedule should be stored in the database with the BAR?
#
# cx_memberships? Offers cyclocross memberships
# eager_match_on_license? Trust license number in results? Use it to match People instead of name.
class RacingAssociation < ApplicationRecord
  # TODO: bmx_numbers? Shouldn"t this be in disciplines?

  belongs_to :cat4_womens_race_series_category, class_name: "Category"
  belongs_to :default_region, class_name: "Region", optional: true

  attr_writer :person

  serialize :administrator_tabs
  serialize :cat4_womens_race_series_points
  serialize :competitions
  serialize :membership_email
  serialize :sanctioning_organizations

  default_value_for :administrator_tabs do
    Set.new(%i[schedule first_aid people teams velodromes categories cat4_womens_race_series article_categories articles pages])
  end

  default_value_for :cat4_womens_race_series_category_id do
    Category.find_or_create_by(name: "Category 4 Women").id
  end

  default_value_for :competitions do
    Set.new(%i[age_graded_bar bar ironman overall_bar team_bar])
  end

  # String
  default_value_for :default_sanctioned_by, &:short_name

  default_value_for :membership_email, &:email

  default_value_for :sanctioning_organizations do
    ["FIAC", "CBRA", "UCI", "USA Cycling"]
  end

  def self.current
    @current ||= RacingAssociation.first || RacingAssociation.create
  end

  class << self
    attr_writer :current
  end

  # Person record for RacingAssociation
  def person
    @person ||= Person.find_or_create_by(name: short_name)
  end

  def person_id
    @person_id ||= person.id
  end

  # Returns now.beginning_of_day, which is the same as Time.zone.today
  def today
    Time.zone.now.to_date
  end

  # Returns now.year, which is the same as Time.zone.today.
  def year
    Time.zone.now.year
  end

  # "Membership year." Used for race number export, schedule, and renewals. Returns current year until December.
  # On and after December 15, returns the next year.
  def effective_year
    if next_year_start_at && Time.zone.now < 1.year.from_now(next_year_start_at)
      if Time.zone.now < next_year_start_at
        return Time.zone.now.year
      elsif Time.zone.now >= next_year_start_at
        if Time.zone.now.year == next_year_start_at.year
          return Time.zone.now.year + 1
        else
          return Time.zone.now.year
        end
      end
    else
      return Time.zone.now.year + 1 if Time.zone.now.month == 12 && Time.zone.now.day >= 1
    end

    Time.zone.now.year
  end

  def effective_today
    if effective_year == Time.zone.now.year
      Time.zone.today
    else
      Time.zone.local(effective_year).beginning_of_year.to_date
    end
  end

  def effective_year_range
    RacingAssociation.current.effective_today.beginning_of_year..RacingAssociation.current.effective_today.end_of_year
  end

  # Time.zone.today.year + 1
  def next_year
    if effective_year == Time.zone.now.year
      effective_year + 1
    else
      effective_year
    end
  end

  def cyclocross_season?
    RacingAssociation.current.today >= cyclocross_season_start.to_date && RacingAssociation.current.today <= cyclocross_season_end.to_date
  end

  def cyclocross_season_start
    Time.zone.local(Time.zone.now.year, 8, 23).beginning_of_day
  end

  def cyclocross_season_end
    Time.zone.local(Time.zone.now.year, 12, 1).end_of_day
  end

  def rental_numbers
    rental_numbers_start..rental_numbers_end if rental_numbers_start && rental_numbers_end
  end

  def rental_numbers=(value)
    if value.nil?
      self.rental_numbers_start = nil
      self.rental_numbers_end = nil
    else
      self.rental_numbers_start = value.first
      self.rental_numbers_end = value.last
    end
  end

  def number_issuer
    @number_issuer ||= NumberIssuer.where(name: short_name).first
  end

  def priority_country_options
    if country_code == "US"
      [["United States", "US"], %w[Canada CA]]
    else
      [%w[Canada CA], ["United States", "US"]]
    end
  end

  def to_s
    "#<RacingAssociation #{short_name} #{name}>"
  end
end
