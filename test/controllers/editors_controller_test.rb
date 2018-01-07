# frozen_string_literal: true

require File.expand_path("../../test_helper", __FILE__)

# :stopdoc:
class EditorsControllerTest < ActionController::TestCase
  def setup
    super
    use_ssl
  end

  test "create" do
    promoter = FactoryBot.create(:promoter)
    member = FactoryBot.create(:person_with_login)

    login_as member
    post :create, id: member.to_param, editor_id: promoter.to_param
    assert_redirected_to edit_person_path(member)

    assert member.editors.include?(promoter), "Should add promoter as editor of member"
  end

  test "create by get" do
    promoter = FactoryBot.create(:promoter)
    member = FactoryBot.create(:person_with_login)

    login_as member
    get :create, id: member.to_param, editor_id: promoter.to_param
    assert_redirected_to edit_person_path(member)

    assert member.editors.include?(promoter), "Should add promoter as editor of member"
  end

  test "create as admin" do
    administrator = FactoryBot.create(:administrator)
    promoter = FactoryBot.create(:promoter)
    member = FactoryBot.create(:person_with_login)

    login_as administrator
    post :create, id: member.to_param, editor_id: promoter.to_param
    assert_redirected_to edit_person_path(member)

    assert member.editors.include?(promoter), "Should add promoter as editor of member"
  end

  test "login required" do
    promoter = FactoryBot.create(:promoter)
    member = FactoryBot.create(:person)
    post :create, id: member.to_param, editor_id: promoter.to_param
    assert_redirected_to new_person_session_url(secure_redirect_options)
  end

  test "security" do
    promoter = FactoryBot.create(:promoter)
    member = FactoryBot.create(:person_with_login)

    login_as promoter
    post :create, id: member.to_param, editor_id: promoter.to_param
    assert_redirected_to unauthorized_path

    assert !member.editors.include?(promoter), "Should not add promoter as editor of member"
  end

  test "already exists" do
    promoter = FactoryBot.create(:promoter)
    member = FactoryBot.create(:person_with_login)

    member.editors << promoter

    login_as member
    post :create, id: member.to_param, editor_id: promoter.to_param
    assert_redirected_to edit_person_path(member)

    assert member.editors.include?(promoter), "Should add promoter as editor of member"
  end

  test "admin" do
    administrator = FactoryBot.create(:administrator)
    promoter = FactoryBot.create(:promoter)
    member = FactoryBot.create(:person_with_login)

    login_as administrator
    post :create, id: member.to_param, editor_id: promoter.to_param, return_to: "admin"
    assert_redirected_to edit_admin_person_path(member)

    assert member.editors.include?(promoter), "Should add promoter as editor of member"
  end

  test "person not found" do
    member = FactoryBot.create(:person_with_login)

    login_as member
    assert_raise(ActiveRecord::RecordNotFound) { post :create, editor_id: "37812361287", id: member.to_param }
  end

  test "editor not found" do
    member = FactoryBot.create(:person_with_login)

    login_as member
    assert_raise(ActiveRecord::RecordNotFound) { post :create, editor_id: member.to_param, id: "2312631872343" }
  end

  test "deny access" do
    promoter = FactoryBot.create(:promoter)
    member = FactoryBot.create(:person_with_login)

    member.editors << promoter

    login_as member
    delete :destroy, id: member.to_param, editor_id: promoter.to_param
    assert_redirected_to edit_person_path(member)

    assert !member.editors.include?(promoter), "Should remove promoter as editor of member"
  end

  test "deny access by get" do
    promoter = FactoryBot.create(:promoter)
    member = FactoryBot.create(:person_with_login)

    member.editors << promoter

    login_as member
    get :destroy, id: member.to_param, editor_id: promoter.to_param
    assert_redirected_to edit_person_path(member)

    assert !member.editors.include?(promoter), "Should remove promoter as editor of member"
  end
end
