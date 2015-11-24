class AddSerializedCompetitionRules < ActiveRecord::Migration
  def change
    change_table :events, force: true do |t|
      t.text :place_bonus
      t.text :point_schedule
    end

    rename_column :events, :points_schedule_from_field_size, :point_schedule_from_field_size

    reversible do |m|
      m.up do
        transaction do
          (Competitions::MbraBar.all + Competitions::MbraTeamBar.all).each do |c|
            c.place_bonus = [ 6, 3, 1 ]
            c.save!
          end

          Competitions::Competition.all.each do |c|
            c.point_schedule = nil
            c.save!
          end

          Competitions::Bar.all.each do |c|
            c.point_schedule = [ 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 ]
            c.save!
          end

          (Competitions::BlindDateAtTheDairyMonthlyStandings.all + Competitions::BlindDateAtTheDairyMonthlyStandings.all).each do |c|
            c.point_schedule = [ 15, 12, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 ]
            c.save!
          end

          Competitions::BlindDateAtTheDairyTeamCompetition.all.each do |c|
            c.point_schedule = [ 15, 12, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 ]
            c.save!
          end

          Competitions::CrossCrusadeCallups.all.each do |c|
            c.point_schedule = [ 15, 12, 10, 8, 7, 6, 5, 4, 3, 2 ]
            c.save!
          end

          Competitions::CrossCrusadeOverall.all.each do |c|
            c.point_schedule = [ 26, 20, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 ]
            c.save!
          end

          Competitions::OregonCup.all.each do |c|
            c.point_schedule = [ 100, 75, 60, 50, 45, 40, 35, 30, 25, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10 ]
            c.save!
          end

          Competitions::OregonJuniorCyclocrossSeries::Overall.all.each do |c|
            c.point_schedule = [ 30, 28, 26, 24, 22, 20, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 ]
            c.save!
          end

          Competitions::OregonTTCup.all.each do |c|
            c.point_schedule = [ 20, 17, 15, 13, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 ]
            c.save!
          end

          (Competitions::OregonWomensPrestigeSeries.all + Competitions::OregonWomensPrestigeTeamSeries.all).each do |c|
            c.point_schedule = [ 100, 80, 70, 60, 55, 50, 45, 40, 35, 30, 25, 20, 18, 16, 14, 12, 10, 8, 6, 4 ] + ([ 2 ] * 80)
            c.save!
          end

          Competitions::OverallBar.all.each do |c|
            c.point_schedule = (1..300).to_a.reverse
            c.save!
          end

          Competitions::TaborOverall.all.each do |c|
            c.point_schedule = [ 100, 70, 50, 40, 36, 32, 28, 24, 20, 16, 15, 14, 13, 12, 11 ]
            c.save!
          end

          (Competitions::PortlandShortTrackSeries::MonthlyStandings.all + Competitions::PortlandShortTrackSeries::Overall.all + Competitions::PortlandShortTrackSeries::TeamStandings.all).each do |c|
            c.point_schedule = [ 100, 80, 60, 50, 45, 40, 36, 32, 29, 26, 24, 22, 20, 18, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 ]
            c.save!
          end
        end
      end
    end
  end
end
