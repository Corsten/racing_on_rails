class AddCompetitionsEnabled < ActiveRecord::Migration
  def change
    add_column :events, :enabled, :boolean, default: true, null: false

    Competitions::Competition.update_all enabled: false

    case RacingAssociation.current.short_name
    when "MBRA"
      Competitions::MbraBar.update_all enabled: true
      Competitions::MbraTeamBar.update_all enabled: true
    when "OBRA"
      Competitions::CrossCrusadeOverall.update_all enabled: true
      Competitions::CrossCrusadeTeamCompetition.update_all enabled: true
      Competitions::TaborOverall.update_all enabled: true
      Competitions::Ironman.update_all enabled: true
      Competitions::OregonCup.update_all enabled: true
      Competitions::OregonJuniorCyclocrossSeries::Overall.update_all enabled: true
      Competitions::OregonJuniorCyclocrossSeries::Team.update_all enabled: true
      Competitions::BlindDateAtTheDairyOverall.update_all enabled: true
      Competitions::BlindDateAtTheDairyTeamCompetition.update_all enabled: true
      Competitions::OregonTTCup.update_all enabled: true
      Competitions::Bar.update_all enabled: true
      Competitions::TeamBar.update_all enabled: true
      Competitions::OverallBar.update_all enabled: true
      Competitions::AgeGradedBar.update_all enabled: true
      Competitions::PortlandShortTrackSeries::Overall.update_all enabled: true
      Competitions::PortlandShortTrackSeries::TeamStandings.update_all enabled: true
    end
  end
end
