# frozen_string_literal: true

require "test_helper"

# :stopdoc:
class Calculations::V3::CalculationTest < ActiveSupport::TestCase
  test "simplest #calculate!" do
    series = WeeklySeries.create!(name: "Cross Crusade")
    source_child_event = series.children.create!

    calculation = series.calculations.create!(points_for_place: [100, 50, 25, 12])
    category = Category.find_or_create_by(name: "Men A")
    calculation.categories << category

    source_race = source_child_event.races.create!(category: category)
    person = FactoryBot.create(:person)
    source_result = source_race.results.create!(place: 1, person: person)

    calculation.calculate!

    overall = calculation.reload.event
    assert series.children.reload.include?(overall), "should add overall as child event"
    assert_equal "Overall", overall.name
    assert_equal "Cross Crusade: Overall", calculation.name

    assert_equal 1, overall.races.size
    men_a_overall_race = overall.races.detect { |race| race.category == category }
    assert_not_nil(men_a_overall_race, "Should have Men A overall race")

    results = men_a_overall_race.results
    assert_equal 1, results.size

    result = results.first
    assert_equal person, result.person
    assert_equal "1", result.place
    assert_equal 100, result.points

    assert_equal 1, result.sources.size
    source = result.sources.first
    assert_equal 100, source.points
    assert_nil source.rejection_reason
    assert_equal source_result, source.source_result

    calculation.reload.calculate!
    assert_equal 1, Calculations::V3::Calculation.count, "Reuse existing event"
    assert_equal 2, series.children.count, "Reuse existing event"
  end

  test "previous year #calculate!" do
    date = 1.year.ago
    series = WeeklySeries.create!(date: date)
    source_child_event = series.children.create!

    calculation = series.calculations.create!(points_for_place: [100, 50, 25, 12])
    category = Category.find_or_create_by(name: "Men A")
    calculation.categories << category

    source_race = source_child_event.races.create!(category: category)
    person = FactoryBot.create(:person)
    source_result = source_race.results.create!(place: 1, person: person)

    calculation.calculate!

    overall = calculation.reload.event
    assert series.children.reload.include?(overall), "should add overall as child event"
    assert_equal_dates date, overall.date
    assert_equal_dates date, overall.end_date

    assert_equal 1, overall.races.size
    men_a_overall_race = overall.races.detect { |race| race.category == category }
    assert_not_nil(men_a_overall_race, "Should have Men A overall race")

    results = men_a_overall_race.results
    assert_equal 1, results.size

    result = results.first
    assert_equal person, result.person
    assert_equal "1", result.place
    assert_equal 100, result.points

    assert_equal 1, result.sources.size
    source = result.sources.first
    assert_equal 100, source.points
    assert_nil source.rejection_reason
    assert_equal source_result, source.source_result
  end

  test "series #calculate!" do
    previous_year_series = WeeklySeries.create!(date: 1.year.ago)
    men_a = Category.find_or_create_by_normalized_name("Men A")
    source_child_event = previous_year_series.children.create!(date: 1.year.ago)
    source_race = source_child_event.races.create!(category: men_a)
    source_race.results.create!(place: 1, person: FactoryBot.create(:person))
    source_race.results.create!(place: 2, person: FactoryBot.create(:person))

    different_series = WeeklySeries.create!
    source_child_event = different_series.children.create!
    source_race = source_child_event.races.create!(category: men_a)
    team = FactoryBot.create(:team)
    person_1 = FactoryBot.create(:person, team: team)
    source_race.results.create!(place: 1, person: person_1, team: team)
    source_race.results.create!(place: 2, person: FactoryBot.create(:person))

    series = WeeklySeries.create!
    source_child_event = series.children.create!

    calculation = series.calculations.create!(
      double_points_for_last_event: true,
      points_for_place: [100, 90, 75, 50, 40, 30, 20, 10]
    )
    calculation.categories << men_a

    source_race = source_child_event.races.create!(category: men_a)
    source_result_1 = source_race.results.create!(place: 1, person: person_1, team: team)
    person_2 = FactoryBot.create(:person)
    source_result_2 = source_race.results.create!(place: 2, person: person_2)

    women_b = Category.find_or_create_by_normalized_name("Women B")
    source_race = source_child_event.races.create!(category: women_b)
    person_3 = FactoryBot.create(:person)
    source_result_3 = source_race.results.create!(place: 1, person: person_3)

    calculation.calculate!

    overall = calculation.reload.event
    assert series.children.reload.include?(overall), "should add overall as child event"

    assert_equal 2, overall.races.size, overall.races.map(&:name)
    men_a_overall_race = overall.races.detect { |race| race.category == men_a }
    assert_not_nil(men_a_overall_race, "Should have Men A overall race")

    results = men_a_overall_race.results.sort
    assert_equal 2, results.size

    result = results.first
    assert_equal person_1, result.person
    assert_equal "1", result.place
    assert_equal 200, result.points
    assert_equal team, result.team

    assert_equal 1, result.sources.size
    source = result.sources.first
    assert_equal 200, source.points
    assert_nil source.rejection_reason
    assert_equal source_result_1, source.source_result

    result = results.second
    assert_equal person_2, result.person
    assert_equal "2", result.place
    assert_equal 180, result.points

    assert_equal 1, result.sources.size
    source = result.sources.first
    assert_equal 180, source.points
    assert_nil source.rejection_reason
    assert_equal source_result_2, source.source_result

    women_b_overall_race = overall.races.detect { |race| race.category == women_b }
    assert_not_nil(women_b_overall_race, "Should have Women B overall race")
    assert women_b_overall_race.rejected?
    assert_equal "not_calculation_category", women_b_overall_race.rejection_reason

    results = women_b_overall_race.results.sort
    assert_equal 1, results.size

    result = results.first
    assert_equal person_3, result.person
    assert_equal "", result.place
    assert_equal 0, result.points
    assert_equal 1, result.sources.size
    source = result.sources.first
    assert_equal 0, source.points
    assert source.rejected?
    assert_equal "not_calculation_category", source.rejection_reason
    assert_equal source_result_3, source.source_result
  end

  test "#source_results" do
    FactoryBot.create(:result)

    series = WeeklySeries.create!
    source_child_event = series.children.create!

    category = Category.find_or_create_by(name: "Men A")
    source_race = source_child_event.races.create!(category: category)
    person = FactoryBot.create(:person)
    source_race.results.create!(place: 1, person: person)

    # Existing Competition results should be ignored
    overall = series.children.create!
    overall_race = overall.races.create!(category: category)
    overall_race.results.create!(place: 1, person: person, competition_result: true)

    calculation = series.calculations.create!(source_event: series)
    assert_equal 1, calculation.source_results.size
  end
end