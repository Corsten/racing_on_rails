# frozen_string_literal: true

require_relative "../acceptance_test"

# :stopdoc:
class EventsTest < AcceptanceTest
  test "events" do
    javascript!

    candi = FactoryBot.create(:person, name: "Candi Murray", home_phone: "(503) 555-1212", email: "admin@example.com")
    gl = FactoryBot.create(:team, name: "Gentle Lovers")
    kings_valley = FactoryBot.create(:event, name: "Kings Valley Road Race", date: "2003-12-31")
    race_1 = kings_valley.races.create!(category: FactoryBot.create(:category, name: "Senior Men Pro/1/2"))
    kings_valley.races.create!(category: FactoryBot.create(:category, name: "Senior Men 3"))

    visit "/"
    login_as FactoryBot.create(:administrator)

    click_link "New Event"

    fill_in "event_name", with: "Sausalito Criterium"
    click_button "Save"
    wait_for_page_content "Created Sausalito Criterium"

    visit "/admin/events"
    assert_page_has_content "Sausalito Criterium"
    click_link "Sausalito Criterium"

    assert_equal "", find("#event_promoter_id", visible: false).value
    assert_equal "", find("#promoter_autocomplete").value
    type_in "promoter_autocomplete", with: "Tom Brown"

    click_button "Save"
    assert_match /\d+/, find("#event_promoter_id", visible: false).value
    assert page.has_field?("promoter_autocomplete", with: "Tom Brown")

    visit "/admin/events"
    assert_page_has_content "Sausalito Criterium"
    click_link "Sausalito Criterium"
    assert_match /\d+/, find("#event_promoter_id", visible: false).value
    assert page.has_field?("promoter_autocomplete", with: "Tom Brown")

    click_link "edit_promoter_link"
    assert page.has_field?("First Name", with: "Tom")
    assert page.has_field?("Last Name", with: "Brown")

    fill_in "First Name", with: "Tim"
    click_button "Save"

    click_link "back_to_event"

    assert_match /\d+/, find("#event_promoter_id", visible: false).value
    assert page.has_field?("promoter_autocomplete", with: "Tim Brown")

    type_in "promoter_autocomplete", with: "candi m"
    find("li#person_#{candi.id} a").click
    assert page.has_field?("promoter_autocomplete", with: "Candi Murray")

    click_button "Save"

    assert_equal candi.id.to_s, find("#event_promoter_id", visible: false).value
    assert page.has_field?("promoter_autocomplete", with: "Candi Murray")

    fill_in "promoter_autocomplete", with: ""
    click_button "Save"

    assert_equal "", find("#event_promoter_id", visible: false).value
    assert page.has_field?("promoter_autocomplete", with: "")

    assert_equal "", find("#event_team_id", visible: false).value
    assert_equal "", find("#team_autocomplete").value

    assert_equal "", find("#event_phone").value
    assert_equal "", find("#event_email").value

    fill_in "event_phone", with: "(541) 212-9000"
    fill_in "event_email", with: "event@google.com"
    click_button "Save"

    assert page.has_field?("event_phone", with: "(541) 212-9000")
    assert page.has_field?("event_email", with: "event@google.com")

    visit "/admin/people/#{candi.id}/edit"
    assert page.has_field?("person_home_phone", with: "(503) 555-1212")
    assert page.has_field?("person_email", with: "admin@example.com")

    visit "/admin/events"
    click_link "Sausalito Criterium"

    type_in "team_autocomplete", with: "Gentle Lovers"
    find("li#team_#{gl.id} a").click
    assert page.has_field?("team_autocomplete", with: "Gentle Lovers")

    click_button "Save"

    assert_equal gl.id.to_s, find("#event_team_id", visible: false).value
    assert_equal "Gentle Lovers", find("#team_autocomplete").value

    fill_in "team_autocomplete", with: ""
    click_button "Save"

    assert_equal "", find("#event_team_id", visible: false).value
    assert_equal "", find("#team_autocomplete").value

    fill_in "Date", with: "Nov 13, 2013"
    click_button "Save"

    event = Event.order(:updated_at).last

    assert_equal "Wednesday, November 13, 2013", find("#event_human_date").value
    assert_equal Time.zone.local(2013, 11, 13).to_date, event.reload.date, "date should be updated in DB"

    wait_for "#event_human_date_picker"
    find("#event_human_date_picker").click
    wait_for ".datepicker-days td.day.old"
    first(".datepicker-days td.day.old", text: "31").click
    wait_for_ajax
    assert_equal "Thursday, October 31, 2013", find("#event_human_date").value
    click_button "Save"

    assert_equal "Thursday, October 31, 2013", find("#event_human_date").value
    assert_equal Time.zone.local(2013, 10, 31).to_date, event.reload.date, "date should be updated in DB"

    click_link "Delete"

    assert_page_has_content "Deleted Sausalito Criterium"

    visit "/admin/events?year=2004"
    assert_no_text "Sausalito Criterium"

    visit "/admin/events?year=2003"

    assert_page_has_content "Import Schedule"

    visit_event kings_valley

    wait_for_page_content "Senior Men Pro/1/2"
    assert_page_has_content "Senior Men Pro/1/2"
    assert_page_has_content "Senior Men 3"

    kings_valley = Event.find_by(name: "Kings Valley Road Race", date: "2003-12-31")
    click_link "destroy_race_#{race_1.id}"

    visit "/admin/events?year=2003"
    visit_event kings_valley

    click_ok_on_confirm_dialog
    click_link "destroy_races"

    visit "/admin/events?year=2003"

    visit_event kings_valley
    assert_no_text "Senior Men Pro/1/2"
    assert_no_text "Senior Men 3"

    click_link "new_event"
    assert_page_has_content "Kings Valley Road Race"
    assert_equal kings_valley.to_param, find("#event_parent_id", visible: false).value

    fill_in "event_name", with: "Fancy New Child Event"
    click_button "Save"
    assert_equal kings_valley.to_param, find("#event_parent_id", visible: false).value

    visit "/admin/events/#{kings_valley.id}/edit"
    assert_page_has_content "Fancy New Child Event"

    click_link "Edit all"
    wait_for "#races_collection_text"

    fill_in "races_collection_text", with: "Men A\nMen B"
    click_button "races_collections_save"

    wait_for "#edit_all"
    assert page.has_css?("td.race", text: "Men A")
    assert page.has_css?("td.race", text: "Men B")

    click_link "Edit all"
    wait_for "#races_collection_text"
    assert_match /Men A[\s]+Men B/, find("#races_collection_text").value

    fill_in "races_collection_text", with: "Women"
    click_link "Cancel"

    wait_for "#edit_all"
    assert page.has_css?("td.race", text: "Men A")
    assert page.has_css?("td.race", text: "Men B")
    assert !page.has_css?("td.race", text: "Women")
  end
end
