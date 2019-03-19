# frozen_string_literal: true

require "test_helper"

module Calculations
  # :stopdoc:
  class ResultsControllerTest < ActionController::TestCase
    test "event index" do
      event = FactoryBot.create(:event)
      get :index, params: { event_id: event }
    end

    test "race index" do
      race = FactoryBot.create(:race)
      get :index, params: { race_id: race }
    end
  end
end