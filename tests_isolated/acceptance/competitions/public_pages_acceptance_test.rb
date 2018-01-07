# frozen_string_literal: true

require_relative "../acceptance_test"

module Competitions
  # :stopdoc:
  class PublicPagesAcceptanceTest < AcceptanceTest
    test "popular pages" do
      create_results

      Ironman.calculate!

      visit "/ironman"
      assert_page_has_content "Ironman"

      visit "/rider_rankings"
      assert_page_has_content "WSBA is using the default USA Cycling ranking system from 2012 onward"

      visit "/cat4_womens_race_series"
      assert_page_has_content "No results for #{RacingAssociation.current.effective_year}"

      visit "/oregon_cup"
      assert_page_has_content "Oregon Cup"
    end

    test "bar" do
      FactoryBot.create(:discipline, name: "Overall")
      FactoryBot.create(:discipline, name: "Mountain Bike")
      age_graded = FactoryBot.create(:discipline, name: "Age Graded")
      masters_men = FactoryBot.create(:category, name: "Masters Men")
      masters_30_34 = FactoryBot.create(:category, name: "Masters Men 30-34", ages: 30..34, parent: masters_men)
      FactoryBot.create(:category, name: "Masters Men 35-39", ages: 35..39, parent: masters_men)
      age_graded.bar_categories << masters_30_34

      road = FactoryBot.create(:discipline, name: "Road")
      road.bar_categories << masters_men

      # Masters 30-34 result. (32)
      weaver = FactoryBot.create(:person, date_of_birth: Date.new(1977))
      banana_belt_1 = FactoryBot.create(:event, date: Date.new(2009, 3))

      Timecop.freeze(2009, 4) do
        banana_belt_masters_30_34 = banana_belt_1.races.create!(category: masters_30_34)
        banana_belt_masters_30_34.results.create!(person: weaver, place: "10")

        Bar.calculate! 2009
        OverallBar.calculate! 2009
        AgeGradedBar.calculate! 2009
      end

      Bar.calculate!
      OverallBar.calculate!
      AgeGradedBar.calculate!

      visit "/bar"
      assert_page_has_content "BAR"
      assert_page_has_content "Oregon Best All-Around Rider"

      visit "/bar/2009"
      page.has_css?("title", text: /BAR/)

      visit "/bar/2009/age_graded"
      assert_page_has_content "Masters Men 30-34"

      visit "/bar/#{Time.zone.today.year}"
      assert_page_has_content "Overall"

      visit "/bar/#{Time.zone.today.year}/age_graded"
      page.has_css?("title", text: /Age Graded/)
    end

    private

    def create_results
      FactoryBot.create(:discipline, name: "Road")
      FactoryBot.create(:discipline, name: "Track")
      FactoryBot.create(:discipline, name: "Time Trial")
      FactoryBot.create(:discipline, name: "Cyclocross")

      promoter = FactoryBot.create(:person, name: "Brad Ross", home_phone: "(503) 555-1212")
      @new_event = FactoryBot.create(:event, promoter: promoter, date: Date.new(RacingAssociation.current.effective_year, 5))
      @alice = FactoryBot.create(:person, name: "Alice Pennington")
      Timecop.freeze(Date.new(RacingAssociation.current.effective_year, 5, 2)) do
        FactoryBot.create(:result, event: @new_event)
      end

      FactoryBot.create(:event, name: "Kings Valley Road Race", date: Time.zone.local(2004).end_of_year.to_date)
                .races.create!(category: FactoryBot.create(:category, name: "Senior Women 1/2/3"))
                .results.create!(place: "2", person: @alice)

      event = FactoryBot.create(:event, name: "Jack Frost", date: Time.zone.local(2002, 1, 17), discipline: "Time Trial")
      event.races.create!(category: FactoryBot.create(:category, name: "Senior Women")).results.create!(place: "1", person: @alice)
      weaver = FactoryBot.create(:person, name: "Ryan Weaver")
      event.races.create!(category: FactoryBot.create(:category, name: "Senior Men")).results.create!(place: "2", person: weaver)

      FactoryBot.create(:team, name: "Gentle Lovers")
      FactoryBot.create(:team, name: "Vanilla")
    end
  end
end
