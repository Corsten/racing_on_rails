# frozen_string_literal: true

require_relative "../test_helper"

# :stopdoc:
class HomeControllerTest < ActionController::TestCase
  test "index" do
    FactoryBot.create(:event, date: 3.weeks.from_now)
    FactoryBot.create(:event, sanctioned_by: "USA Cycling")
    Home.create!(weeks_of_upcoming_events: 4)

    get :index

    assert_response :success
    assert_nil assigns["upcoming_events"], "@upcoming_events"
    assert_not_nil assigns["events_with_recent_results"], "@events_with_recent_results"
    assert assigns["most_recent_event_with_recent_result"].empty?, "@most_recent_event_with_recent_result"
    assert assigns["news_category"].empty?, "@news_category"
    assert assigns["recent_news"].empty?, "@recent_news"
  end

  test "edit" do
    use_ssl
    login_as :administrator
    get :edit
    assert_response :success
  end

  test "edit should require administrator" do
    use_ssl
    get :edit
    assert_redirected_to new_person_session_path
  end

  test "update" do
    use_ssl
    login_as :administrator
    put :update, home: { weeks_of_recent_results: 1 }
    assert_redirected_to edit_home_path
  end
end
