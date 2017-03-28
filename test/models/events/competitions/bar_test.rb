# There is duplication between BAR tests, but refactoring the tests should wait until the Competition refactoring is complete
# FIXME Assert correct team names on BAR results

require File.expand_path("../../../../test_helper", __FILE__)

module Competitions
  # :stopdoc:
  class BarTest < ActiveSupport::TestCase
    test "calculate" do
      alice  = FactoryGirl.create(:person, name: "Alice")
      matson = FactoryGirl.create(:person, name: "Matson")
      molly  = FactoryGirl.create(:person, name: "Molly")
      tonkin = FactoryGirl.create(:person, name: "Tonkin")
      weaver = FactoryGirl.create(:person, name: "Weaver")

      association_category = FactoryGirl.create(:category, name: "CBRA")
      senior_men           = FactoryGirl.create(:category, name: "Senior Men", parent: association_category)
      men_a                = FactoryGirl.create(:category, name: "Men A", parent: senior_men)
      sr_p_1_2             = FactoryGirl.create(:category, name: "Senior Men Pro/1/2", parent: senior_men)
      senior_women         = FactoryGirl.create(:category, name: "Senior Women", parent: association_category)

      discipline = FactoryGirl.create(:discipline, name: "Road")
      discipline.bar_categories << senior_men
      discipline.bar_categories << senior_women

      discipline = FactoryGirl.create(:discipline, name: "Time Trial")
      discipline.bar_categories << senior_men
      discipline.bar_categories << senior_women

      discipline = FactoryGirl.create(:discipline, name: "Cyclocross")
      discipline.bar_categories << men_a

      discipline = FactoryGirl.create(:discipline, name: "Track")
      discipline.bar_categories << senior_men

      discipline = FactoryGirl.create(:discipline, name: "Criterium")
      discipline.bar_categories << senior_men

      cross_crusade = Series.create!(name: "River City Bicycles Cyclocross Crusade", discipline: "Cyclocross")
      barton = SingleDayEvent.create!(
        name: "Cross Crusade: Barton Park",
        discipline: "Cyclocross",
        date: Date.new(2004, 11, 7),
        parent: cross_crusade
      )
      barton_a = barton.races.create!(category: men_a, field_size: 5)
      barton_a.results.create!(
        place: 3,
        person: tonkin
      )
      barton_a.results.create!(
        place: 15,
        person: weaver
      )
      barton_a.results.create!(
        place: 2,
        person: alice,
        bar: false
      )

      # Parent with different discipline
      stage_race = MultiDayEvent.create!(discipline: "Road")
      swan_island = SingleDayEvent.create!(
        name: "Swan Island",
        discipline: "Criterium",
        date: Date.new(2004, 5, 17),
        parent: stage_race
      )
      swan_island_senior_men = swan_island.races.create!(category: sr_p_1_2, field_size: 4)
      swan_island_senior_men.results.create!(
        place: 12,
        person: tonkin
      )
      swan_island_senior_men.results.create!(
        place: 2,
        person: molly
      )
      # No BAR points
      senior_women_swan_island = swan_island.races.create!(category: senior_women, field_size: 3, bar_points: 0)
      senior_women_swan_island.results.create!(
        place: 1,
        person: molly
      )

      thursday_track_series = Series.create!(name: "Thursday Track", discipline: "Track")
      thursday_track = SingleDayEvent.create!(
        name: "Thursday Track",
        discipline: "Track",
        date: Date.new(2004, 5, 12),
        parent: thursday_track_series
      )
      thursday_track_senior_men = thursday_track.races.create!(category: senior_men, field_size: 6)
      thursday_track_senior_men.results.create!(
        place: 5,
        person: weaver
      )
      thursday_track_senior_men.results.create!(
        place: 14,
        person: tonkin
      )

      team_track = SingleDayEvent.create!(
        name: "Team Track State Championships",
        discipline: "Track",
        date: Date.new(2004, 9, 1),
        bar_points: 2
      )
      team_track_senior_men = team_track.races.create!(category: senior_men, field_size: 6)
      team_track_senior_men.results.create!(
        place: 1,
        person: weaver
      )
      team_track_senior_men.results.create!(
        place: 1,
        person: tonkin
      )
      team_track_senior_men.results.create!(
        place: 1,
        person: molly
      )
      team_track_senior_men.results.create!(
        place: 5,
        person: alice
      )
      team_track_senior_men.results.create!(
        place: 5,
        person: matson
      )
      # Weaver and Erik's second ride should not count
      team_track_senior_men.results.create!(
        place: 15,
        person: weaver
      )
      team_track_senior_men.results.create!(
        place: 15,
        person: tonkin
      )

      larch_mt_hillclimb = SingleDayEvent.create!(
        name: "Larch Mountain Hillclimb",
        discipline: "Time Trial",
        date: Date.new(2004, 2, 1)
      )
      larch_mt_hillclimb_senior_men = larch_mt_hillclimb.races.create!(category: senior_men, field_size: 6)
      larch_mt_hillclimb_senior_men.results.create!(
        place: 13,
        person: tonkin
      )

      # Weekly series overall should count, not individual race
      blind_date = WeeklySeries.create!(name: "Blind Date", discipline: "Cyclocross", date: Date.new(2004, 9, 1))
      blind_date
        .races.create!(category: men_a)
        .results.create!(
          place: 15,
          person: tonkin
        )

      blind_date.children.create!(date: Date.new(2004, 9, 1))
                .races.create!(category: men_a)
                .results.create!(
                  place: 1,
                  person: tonkin
                )

      blind_date.children.create!(date: Date.new(2004, 9, 8))
                .races.create!(category: men_a)
                .results.create!(
                  place: 3,
                  person: tonkin
                )

      # Previous year
      event = FactoryGirl.build(:event, date: Date.new(2003))
      FactoryGirl.build(:result, race: FactoryGirl.build(:race, event: event))

      Bar.any_instance.expects(:expire_cache).at_least_once
      assert_difference "Result.count", 10 do
        Bar.calculate! 2004
      end
      assert_equal(5, Bar.year(2004).count, "Bar events after calculate!")
      Bar.where(date: Date.new(2004)).each do |bar|
        assert(bar.name[/2004.*BAR/], "Name #{bar.name} is wrong")
        assert_equal_dates(Time.zone.today, bar.updated_at, "BAR last updated")
      end

      cx_bar = Bar.find_by_name("2004 Cyclocross BAR")
      men_cx_bar = cx_bar.races.detect { |b| b.category == men_a }
      assert_equal(2, men_cx_bar.results.size, "Men A Cyclocross BAR results")

      results = men_cx_bar.results.sort
      assert_equal(tonkin, results[0].person, "Men A Cyclocross BAR results person")
      assert_equal("1", results[0].place, "Men A Cyclocross BAR results place")
      assert_equal(14, results[0].points, "Men A Cyclocross BAR results points")
      assert_equal(2, results[0].scores.size, "Toinkin Men A Cyclocross BAR results scores")

      assert_equal(weaver, results[1].person, "Men A Cyclocross BAR results person")
      assert_equal("2", results[1].place, "Men A Cyclocross BAR results place")
      assert_equal(1, results[1].points, "Men A Cyclocross BAR results points")
      assert_equal(1, results[1].scores.size, "Weaver Men A Cyclocross BAR results scores")

      track_bar = Bar.find_by_name("2004 Track BAR")
      assert_not_nil(track_bar, "Track BAR")
      sr_men_track = track_bar.races.detect { |r| r.category == senior_men }
      assert_not_nil(sr_men_track, "Senior Men Track BAR")
      tonkin_track_bar_result = sr_men_track.results.detect { |result| result.person == tonkin }
      assert_not_nil(tonkin_track_bar_result, "Tonkin Track BAR result")
      assert_equal(12, tonkin_track_bar_result.points, "Tonkin Track BAR points")
    end

    test "calculate team events" do
      person = FactoryGirl.create(:person, name: "Paul Mautner")

      association_category = FactoryGirl.create(:category, name: "CBRA")
      senior_men           = FactoryGirl.create(:category, name: "Senior Men", parent: association_category)

      discipline = FactoryGirl.create(:discipline, name: "Track")
      discipline.bar_categories << senior_men

      team_track = SingleDayEvent.create!(
        name: "Team Track State Championships",
        discipline: "Track",
        date: Date.new(2004, 9, 1),
        bar_points: 2
      )
      team_track_senior_men = team_track.races.create!(category: senior_men)
      team_track_senior_men.results.create!(
        place: 1,
        person: person
      )
      team_track_senior_men.results.create!(
        place: 1,
        person: FactoryGirl.create(:person)
      )
      team_track_senior_men.results.create!(
        place: 1,
        person: FactoryGirl.create(:person)
      )

      Bar.calculate! 2004

      track_bar = Bar.find_by_name("2004 Track BAR")
      sr_men_track = track_bar.races.detect { |r| r.category == senior_men }
      result = sr_men_track.results.detect { |r| r.person == person }
      assert_equal(10, result.points, "points")
    end

    test "masters 4 5" do
      masters_men             = FactoryGirl.create(:category, name: "Masters Men")
      masters_men_4_5         = FactoryGirl.create(:category, name: "Masters Men 4/5", parent: masters_men)
                                FactoryGirl.create(:category, name: "Masters Men 4/5 40+", parent: masters_men_4_5)
                                FactoryGirl.create(:category, name: "Masters Men 4/5 50+", parent: masters_men_4_5)
      masters_men_40_plus     = FactoryGirl.create(:category, name: "Masters Men 40+", parent: masters_men)

      cats = Bar.new.categories_for(Race.new(category: masters_men))
      assert_same_elements [ masters_men, masters_men_40_plus ], cats, "Should include all Masters children except 4/5"
    end

    test "masters women" do
      masters_women           = FactoryGirl.create(:category, name: "Masters Women")
      masters_women_4         = FactoryGirl.create(:category, name: "Masters Women 4", parent: masters_women)
                                FactoryGirl.create(:category, name: "Masters Women 4 40+", parent: masters_women_4)
      masters_women_40_plus   = FactoryGirl.create(:category, name: "Masters Women 40+", parent: masters_women)

      cats = Bar.new.categories_for(Race.new(category: masters_women))
      assert_same_elements [ masters_women, masters_women_40_plus ], cats, "Should include all Masters women children except 4"
    end

    test "#categories_for should not modify association" do
      root = FactoryGirl.create(:category)
      node = FactoryGirl.create(:category, parent: root)
      leaf = FactoryGirl.create(:category, parent: node)

      Bar.new.categories_for(Race.new(category: root.reload))
      Bar.new.categories_for(Race.new(category: node.reload))
      Bar.new.categories_for(Race.new(category: leaf.reload))

      assert_nil root.parent, "root parent"
      assert_equal root, node.parent, "node parent"
      assert_equal node, leaf.parent, "leaf parent"
    end
  end
end
