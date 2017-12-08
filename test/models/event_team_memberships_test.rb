require "test_helper"

# :stopdoc:
class EventTeamMembershipsTest < ActiveSupport::TestCase
  test "create for existing team" do
    person = FactoryBot.create(:person)
    event_team = FactoryBot.create(:event_team)

    new_membership = event_team.event_team_memberships.create!(person: person)

    assert_equal event_team, new_membership.event_team
    assert_equal person, new_membership.person
    assert_equal 1, EventTeamMembership.count
  end

  test "replace with person ID" do
    event_team_membership = FactoryBot.create(:event_team_membership)
    different_team = FactoryBot.create(:event_team, event: event_team_membership.event)

    new_membership = different_team.event_team_memberships.create(person: event_team_membership.person.reload)
    assert new_membership.errors.present?
    assert_equal 1, EventTeamMembership.count
  end

  test "create_or_replace" do
    event_team_membership = FactoryBot.create(:event_team_membership)
    different_team = FactoryBot.create(:event_team, event: event_team_membership.event)

    new_membership = EventTeamMembership.new(
      event_team: event_team_membership.event_team,
      person: event_team_membership.person.reload
    )
    assert new_membership.create_or_replace
    assert !new_membership.errors.present?
    assert_equal 1, EventTeamMembership.count
  end
end
