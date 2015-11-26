class AddSerializedCompetitionRules < ActiveRecord::Migration
  def change
    change_table :events, force: true do |t|
      t.text :category_names
      t.text :place_bonus
      t.text :point_schedule
      t.text :race_category_names
      t.text :source_result_category_names
    end

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

          (Competitions::BlindDateAtTheDairyOverall.all + Competitions::BlindDateAtTheDairyMonthlyStandings.all).each do |c|
            c.point_schedule = [ 15, 12, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 ]
            c.category_names = [
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
            c.save!
          end

          Competitions::BlindDateAtTheDairyTeamCompetition.all.each do |c|
            c.point_schedule = [ 15, 12, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 ]
            c.race_category_names = [ "Team Competition" ]
            c.source_result_category_names = [
              "Beginner Men",
              "Beginner Women",
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

            c.save!
          end

          Competitions::CrossCrusadeCallups.all.each do |c|
            c.point_schedule = [ 15, 12, 10, 8, 7, 6, 5, 4, 3, 2 ]
            c.category_names = [
              "Men A",
              "Men B",
              "Men C",
              "Athena",
              "Clydesdale",
              "Junior Men",
              "Junior Women",
              "Masters 35+ A",
              "Masters 35+ B",
              "Masters 35+ C",
              "Masters 50+",
              "Masters 60+",
              "Masters Women 35+ A",
              "Masters Women 35+ B",
              "Masters Women 45+",
              "Singlespeed Women",
              "Singlespeed",
              "Unicycle",
              "Women A",
              "Women B",
              "Women C"
            ]

            c.save!
          end

          Competitions::CrossCrusadeTeamCompetition.all.each do |c|
            c.point_schedule = (1..100).to_a
            c.race_category_names = [ "Team" ]
            c.save!
          end

          Competitions::CrossCrusadeOverall.all.each do |c|
            c.point_schedule = [ 26, 20, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 ]
            c.category_names =[
              "Athena",
              "Beginner Men",
              "Beginner Women",
              "Category A",
              "Category B",
              "Category C",
              "Clydesdale",
              "Junior Men 10-12",
              "Junior Men 13-14",
              "Junior Men 15-16",
              "Junior Men 17-18",
              "Junior Men",
              "Junior Women 10-12",
              "Junior Women 13-14",
              "Junior Women 15-16",
              "Junior Women 17-18",
              "Junior Women",
              "Masters 35+ A",
              "Masters 35+ B",
              "Masters 35+ C",
              "Masters 50+",
              "Masters 60+",
              "Masters Women 35+ A",
              "Masters Women 35+ B",
              "Masters Women 45+",
              "Singlespeed Women",
              "Singlespeed",
              "Unicycle",
              "Women A",
              "Women B",
              "Women C"
            ]
            c.save!
          end

          Competitions::OregonCup.all.each do |c|
            c.point_schedule = [ 100, 75, 60, 50, 45, 40, 35, 30, 25, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10 ]
            c.category_names = [ "Senior Men" ]
            c.save!
          end

          Competitions::OregonJuniorCyclocrossSeries::Overall.all.each do |c|
            c.point_schedule = [ 30, 28, 26, 24, 22, 20, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 ]
            c.category_names = [
                "Junior Men 10-12",
                "Junior Men 13-14",
                "Junior Men 15-16",
                "Junior Men 17-18",
                "Junior Women 10-12",
                "Junior Women 13-14",
                "Junior Women 15-16",
                "Junior Women 17-18"
              ]
            c.save!
          end

          Competitions::OregonTTCup.all.each do |c|
            c.point_schedule = [ 20, 17, 15, 13, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 ]
            c.category_names = [
              "Category 3 Men",
              "Category 3 Women",
              "Category 4/5 Men",
              "Category 4/5 Women",
              "Eddy Senior Men",
              "Eddy Senior Women",
              "Junior Men 10-12",
              "Junior Men 13-14",
              "Junior Men 15-16",
              "Junior Men 17-18",
              "Junior Women 10-14",
              "Junior Women 15-18",
              "Masters Men 30-39",
              "Masters Men 40-49",
              "Masters Men 50-59",
              "Masters Men 60-69",
              "Masters Men 70+",
              "Masters Women 30-39",
              "Masters Women 40-49",
              "Masters Women 50-59",
              "Masters Women 60-69",
              "Masters Women 70+",
              "Senior Men Pro/1/2",
              "Senior Women 1/2",
              "Tandem"
            ]
            c.save!
          end

          (Competitions::OregonWomensPrestigeSeries.all + Competitions::OregonWomensPrestigeTeamSeries.all).each do |c|
            c.point_schedule = [ 100, 80, 70, 60, 55, 50, 45, 40, 35, 30, 25, 20, 18, 16, 14, 12, 10, 8, 6, 4 ] + ([ 2 ] * 80)
            c.save!
          end

          Competitions::OregonWomensPrestigeSeries.all.each do |c|
            c.category_names = [ "Women 1/2/3", "Women 4" ]
            c.save!
          end

          Competitions::OregonWomensPrestigeTeamSeries.all.each do |c|
            c.category_names = [ "Team" ]
            c.save!
          end

          Competitions::OverallBar.all.each do |c|
            c.point_schedule = (1..300).to_a.reverse
            c.save!
          end

          Competitions::TaborOverall.all.each do |c|
            c.point_schedule = [ 100, 70, 50, 40, 36, 32, 28, 24, 20, 16, 15, 14, 13, 12, 11 ]
            c.category_names = [
              "Category 3 Men",
              "Category 4 Men",
              "Category 4 Women",
              "Category 5 Men",
              "Masters Men 50+",
              "Masters Men 40+",
              "Masters Women",
              "Senior Men",
              "Senior Women"
            ]
            c.save!
          end

          (Competitions::PortlandShortTrackSeries::MonthlyStandings.all + Competitions::PortlandShortTrackSeries::Overall.all + Competitions::PortlandShortTrackSeries::TeamStandings.all).each do |c|
            c.point_schedule = [ 100, 80, 60, 50, 45, 40, 36, 32, 29, 26, 24, 22, 20, 18, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 ]
            c.category_names = [
              "Category 1 Men 19-34",
              "Category 1 Men 35-44",
              "Category 1 Men 45+",
              "Category 2 Men 35-44",
              "Category 2 Men 45-54",
              "Category 2 Men 55+",
              "Category 2 Men U35",
              "Category 2 Women 35-44",
              "Category 2 Women 45+",
              "Category 2 Women U35",
              "Category 3 Men 10-14",
              "Category 3 Men 15-18",
              "Category 3 Men 19-44",
              "Category 3 Men 45+",
              "Category 3 Women 10-14",
              "Category 3 Women 15-18",
              "Category 3 Women 19+",
              "Clydesdale",
              "Elite Men",
              "Elite/Category 1 Women",
              "Singlespeed"
            ]
            c.save!
          end

          Competitions::PortlandShortTrackSeries::TeamStandings.all.each do |c|
            c.race_category_names = [ "Team" ]
            c.save!
          end
        end
      end
    end
  end
end
