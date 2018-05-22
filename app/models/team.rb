# frozen_string_literal: true

# Bike racing team of People
#
# Like People, Teams may have many alternate names. These are modelled as Aliases. Historical names from previous years are stored as Names.
#
# Team names must be unique
class Team < ActiveRecord::Base
  include RacingOnRails::VestalVersions::Versioned
  include Export::Teams
  include Names::Nameable
  include RacingOnRails::PaperTrail::Versions

  before_save :destroy_shadowed_aliases
  after_save :add_alias_for_old_name
  before_destroy :ensure_no_results

  validates :name, presence: true
  validates :name, uniqueness: true

  has_many :aliases, as: :aliasable, dependent: :destroy
  has_many :events
  has_many :event_teams
  has_many :people
  has_many :results

  def self.find_by_name_or_alias(name)
    Team.find_by(name: name) || Alias.where(name: name, aliasable_type: "Team").first&.team
  end

  def self.find_by_name_or_alias_or_create(name)
    find_by_name_or_alias(name) || Team.create(name: name)
  end

  def self.name_like(name)
    name_like = "%#{name}%"
    Team
      .where("teams.name like ? or aliases.name like ?", name_like, name_like)
      .includes(:aliases)
      .references(:aliases)
      .order("teams.name")
  end

  def teams_with_same_name
    teams = Team.where(name: name) | Alias.find_all_teams_by_name(name)
    teams.reject { |team| team == self }
  end

  def ensure_no_results
    return true if no_results?

    errors.add :base, "Cannot delete team with results. #{name} has #{results.count} results."
    false
  end

  def no_results?
    results.count == 0
  end

  def no_people?
    people.count == 0
  end

  # If name changes to match existing alias, destroy the alias
  def destroy_shadowed_aliases
    Alias.destroy_all name: name
  end

  def add_alias_for_old_name
    if !new_record? &&
       name_was.present? &&
       name.present? &&
       name_was.casecmp(name) != 0 &&
       !Alias.exists?(name: name_was, aliasable_id: id, aliasable_type: "Team") &&
       !Team.exists?(name: name_was)

      new_alias = Alias.create!(name: name_was, team: self)
      logger.error("Could not save alias #{new_alias}: #{new_alias.errors.full_messages.join(', ')}") unless new_alias.save
      new_alias
    end
  end

  # Moves another Team's aliases, results, and people to this Team,
  # and delete the other Team.
  # Also adds the other Team's name as a new alias
  def merge(team)
    raise(ArgumentError, "Cannot merge nil team") unless team
    return false if team == self

    Team.transaction do
      reload
      team.reload
      results true
      team.results true
      team.create_team_for_historical_results!
      team.results true

      team.event_teams.each do |event_team|
        event_team.event_team_memberships.each do |event_team_membership|
          new_event_team = EventTeam.where(event: event_team.event, team: self).first_or_create!
          event_team_membership.event_team = new_event_team
          event_team_membership.save!
        end
        event_team.reload.destroy!
      end

      aliases << team.aliases
      events << team.events
      results << team.results
      people << team.people

      Team.delete team.id

      if !Alias.where(name: team.name, aliasable_type: "Team").where.not(aliasable_id: nil).exists? && !Team.where(name: team.name).exists?
        aliases.create! name: team.name
      end
    end
  end

  # Preserve team names in old results by creating a new Team for them, and moving the results.
  #
  # Results are preserved by creating a new Team from the most recent Name. If a Team
  # already exists with the Name's name, results will move to existing Team.
  # This may be unxpected, can't think of a better way to handle it in this model.
  def create_team_for_historical_results!
    name = names.sort_by(&:year).reverse!.first

    if name
      team = Team.find_or_create_by(name: name.name)
      results.each do |r|
        team.results << r if r.date.year <= name.year
      end

      name.destroy
      names.each do |n|
        team.names << n unless name == n
      end
    end
  end

  def member_in_year?(_date)
    member
  end

  def name=(value)
    self.name_was = name unless name_was
    self[:name] = value
  end

  def to_s
    "#<Team #{id} '#{name}'>"
  end
end
