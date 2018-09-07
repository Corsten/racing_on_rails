# frozen_string_literal: true

require File.expand_path("../../test_helper", __FILE__)

# :stopdoc:
class MailingListsControllerTest < ActionController::TestCase
  test "index" do
    get :index
    assert_response(:success)
    assert_template("mailing_lists/index")
    assert_not_nil(assigns["mailing_lists"], "Should assign mailing_lists")
  end

  test "confirm" do
    obra_race = FactoryBot.create(:mailing_list)
    get :confirm, params: { mailing_list_id: obra_race.id }
    assert_response :success
    assert_template "mailing_lists/confirm"
    assert_equal obra_race, assigns["mailing_list"], "Should assign mailing list"
  end

  test "confirm private reply" do
    obra_race = FactoryBot.create(:mailing_list)
    get :confirm_private_reply, params: { mailing_list_id: obra_race.id }
    assert_response(:success)
    assert_template("mailing_lists/confirm_private_reply")
    assert_equal(obra_race, assigns["mailing_list"], "Should assign mailing list")
  end
end
