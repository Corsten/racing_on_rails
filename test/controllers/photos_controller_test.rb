# frozen_string_literal: true

require "test_helper"

class PhotosControllerTest < ActionController::TestCase
  setup :use_ssl

  test "index" do
    FactoryBot.create(:photo)
    login_as :administrator
    get :index
    assert_response :success
  end

  test "empty index" do
    login_as :administrator
    get :index
    assert_response :success
  end

  test "edit" do
    photo = FactoryBot.create(:photo)
    login_as :administrator
    get :edit, params: { params: { id: photo.id } }
    assert_response :success
    assert_equal photo, assigns(:photo), "@photo"
  end

  test "create" do
    login_as :administrator

    Photo.any_instance.stubs height: 300, width: 400

    post :create, params: { params: {
      photo: {
        caption: "Caption",
        image: fixture_file_upload("photo.jpg")
      }
    }}

    assert_redirected_to edit_photo_path(assigns(:photo))
  end

  test "edit should require administrator" do
    photo = FactoryBot.create(:photo)
    get :edit, params: { params: { id: photo.id } }
    assert_redirected_to new_person_session_path
  end

  test "new should require administrator" do
    get :new
    assert_redirected_to new_person_session_path
  end

  test "create should require administrator" do
    post :create, params: { params: {
      photo: {
        caption: "Caption",
        title: "Title",
        image: fixture_file_upload("photo.jpg")
      }
    }}
    assert_redirected_to new_person_session_path
  end

  test "update should require administrator" do
    photo = FactoryBot.create(:photo)
    put :update, params: { params: { id: photo.id, photo: { caption: "New Caption" } } }
    assert_redirected_to new_person_session_path
  end
end
