# frozen_string_literal: true

class CreateEventTeamMemberships < ActiveRecord::Migration
  def change
    create_table :event_teams, force: true do |t|
      t.references :event, null: false
      t.references :team, null: false

      t.timestamps

      t.index :event_id
      t.index :team_id
      t.index %i[event_id team_id], unique: true
    end

    create_table :event_team_memberships, force: true do |t|
      t.references :event_team, null: false
      t.references :person, null: false

      t.timestamps

      t.index :event_team_id
      t.index :person_id
      t.index %i[event_team_id person_id], unique: true
    end
  end
end
