class AddCompetitionRulesToDb < ActiveRecord::Migration
  def change
    change_table :events do |t|
      t.boolean :break_ties, default: true
      t.boolean :categories, default: false
      t.integer :default_bar_points, default: 0
      t.decimal :dnf_points, precision: 10, scale: 2, default: 0.0
      t.boolean :double_points_for_last_event, default: false
      t.boolean :field_size_bonus, default: false
      t.boolean :members_only, default: true
      t.integer :maximum_events
      t.integer :minimum_events
      t.integer :missing_result_penalty
      t.boolean :most_points_win, default: true
      t.boolean :point_schedule_from_field_size, default: false
      t.integer :results_per_race, default: 1
      t.boolean :use_source_result_points, default: false
      t.boolean :team, default: false
    end

    reversible do |m|
      m.up do
        transaction do
          Competitions::AgeGradedBar.update_all use_source_result_points: true
          Competitions::Bar.update_all default_bar_points: true
          Competitions::BlindDateAtTheDairyOverall.update_all maximum_events: 4, members_only: false
          Competitions::BlindDateAtTheDairyMonthlyStandings.update_all default_bar_points: 1, members_only: false
          Competitions::BlindDateAtTheDairyTeamCompetition.update_all members_only: false
          Competitions::CrossCrusadeCallups.update_all members_only: false
          Competitions::CrossCrusadeOverall.update_all minimum_events: 3, maximum_events: 6
          Competitions::CrossCrusadeTeamCompetition.update_all(
            break_ties: false, members_only: false, missing_result_penalty: 100, most_points_win: false
          )
          Competitions::Ironman.update_all break_ties: false, dnf_points: 1
          Competitions::MbraBar.update_all dnf_points: 0.5, members_only: false, point_schedule_from_field_size: true
          Competitions::MbraTeamBar.update_all members_only: false, point_schedule_from_field_size: true, results_per_race: 2
          Competitions::OregonJuniorCyclocrossSeries::Overall.update_all maximum_events: 4, members_only: false
          Competitions::OregonJuniorCyclocrossSeries::Team.update_all maximum_events: 4, members_only: false
          Competitions::OregonWomensPrestigeSeries.update_all categories: true
          Competitions::OregonWomensPrestigeTeamSeries.update_all categories: true, results_per_race: 3
          Competitions::OregonTTCup.update_all maximum_events: 8
          Competitions::Overall.update_all members_only: false
          Competitions::OverallBar.update_all maximum_events: 5
          Competitions::PortlandShortTrackSeries::MonthlyStandings.update_all(
            default_bar_points: 1, members_only: false
          )
          Competitions::PortlandShortTrackSeries::Overall.update_all maximum_events: 7, members_only: false
          Competitions::PortlandShortTrackSeries::TeamStandings.update_all(
            members_only: false, use_source_result_points: true
          )
          Competitions::TaborOverall.update_all default_bar_points: 1, double_points_for_last_event: true
          Competitions::TeamBar.update_all use_source_result_points: true
        end
      end
    end
  end
end
