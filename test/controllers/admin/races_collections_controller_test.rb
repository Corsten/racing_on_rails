# frozen_string_literal: true

require "test_helper"

module Admin
  # :stopdoc:
  class RacesCollectionsControllerTest < ActionController::TestCase
    setup :use_ssl, :create_administrator_session

    test "edit" do
      @controller.expects :require_administrator_or_promoter
      race = FactoryBot.create(:race)
      FactoryBot.create(:race, event: race.event)
      get :edit, params: { event_id: race.event }, xhr: true
      assert_response :success
      assert_not_nil assigns[:races_collection], "@races_collection"
    end

    test "show" do
      @controller.expects :require_administrator_or_promoter
      race = FactoryBot.create(:race)
      FactoryBot.create(:race, event: race.event)
      get :show, params: { event_id: race.event }, xhr: true
      assert_response :success
      assert_not_nil assigns[:races_collection], "@races_collection"
    end

    test "update" do
      @controller.expects :require_administrator_or_promoter
      race = FactoryBot.create(:race)
      FactoryBot.create(:race, event: race.event)
      put :update, params: { event_id: race.event, races_collection: { text: "Senior Men\r\nCat 3" } }, xhr: true
      assert_response :success
      assert_not_nil assigns[:races_collection], "@races_collection"
      assert_equal ["Category 3", "Senior Men"], race.event.races.reload.map(&:name).sort
    end

    test "create" do
      @controller.expects :require_administrator_or_promoter

      previous_year = FactoryBot.create(:event, name: "Tabor", date: 1.year.ago)
      previous_year.races.create! category: FactoryBot.create(:category, name: "Senior Men")
      previous_year.races.create! category: FactoryBot.create(:category, name: "Women 3")

      event = FactoryBot.create(:event, name: "Tabor")
      post :create, params: { event_id: event }, xhr: true
      assert_response :success

      assert_same_elements ["Senior Men", "Women 3"], event.reload.categories.map(&:name)
    end
  end
end
