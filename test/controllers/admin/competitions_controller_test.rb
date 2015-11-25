require 'test_helper'

module Admin
  # :stopdoc:
  class CompetitionsControllerTest < ActionController::TestCase
    setup :create_administrator_session

    test "edit" do
      competition = Competitions::Ironman.create!
      get :edit, id: competition
    end

    test "update" do
      competition = Competitions::Ironman.create!
      patch :update, id: competition, competition: {
        point_schedule_string: "15, 12, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1",
        maximum_events: 10
      }
    end
  end
end
