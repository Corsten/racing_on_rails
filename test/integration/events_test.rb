require_relative "racing_on_rails/integration_test"

# :stopdoc:
class EventsTest < RacingOnRails::IntegrationTest
  test "index" do
    Timecop.freeze(Time.zone.local(2013, 3)) do
      FactoryBot.create(:event)
      FactoryBot.create(:event)

      get "/events"
      assert_redirected_to schedule_path

      get "/events.xml"
      assert_response :success
      xml = Hash.from_xml(response.body)
      assert_not_nil xml["single_day_events"], "Should have :single_day_events root element in #{xml}"

      get "/events.json"
      assert_response :success
      assert_equal 2, JSON.parse(response.body).size, "Should have JSON array"
    end
  end
end
