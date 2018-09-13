# frozen_string_literal: true

require File.expand_path("../../../test_helper", __FILE__)

module Competitions
  # :stopdoc:
  class CompetitionsControllerTest < ActionController::TestCase #:nodoc: all
    # How does this happen?
    test "rider rankings result with no person" do
      RiderRankings.calculate!
      rider_rankings = RiderRankings.find_for_year
      rider_rankings.races.first.results.create!(place: "1")
      get :show, params: { type: "rider_rankings" }
      assert_response(:success)
      assert_template("results/event")
      assert_not_nil(assigns["event"], "Should assign event")
      assert_not_nil(assigns["year"], "Should assign year")
    end

    test "unknown competition type" do
      assert_raise(ActionController::UrlGenerationError) { get(:show, params: { type: "not_a_series" }) }
    end
  end
end
