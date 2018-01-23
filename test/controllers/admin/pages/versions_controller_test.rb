# frozen_string_literal: true

require File.expand_path("../../../../test_helper", __FILE__)

module Admin
  module Pages
    # :stopdoc:
    class VersionsControllerTest < ActionController::TestCase
      def setup
        super
        create_administrator_session
        use_ssl
      end

      test "Edit page version" do
        page = FactoryBot.create(:page)
        page.update title: "New Title"
        version = page.paper_trail_versions.last
        get(:edit, id: version.to_param)
        assert_response(:success)
      end

      test "Show old version" do
        page = Page.create!(body: "<h1>Welcome</h1>")
        page.body = "<h1>foo</h1>"
        page.save!
        page.body = "<h1>TTYL!</h1>"
        page.save!
        get(:show, id: page.paper_trail_versions.first.to_param)
        assert_select("h1", text: "TTYL!")
      end

      test "Delete old version" do
        page = Page.create!(body: "<h1>Welcome</h1>")
        page.body = "<h1>TTYL!</h1>"
        page.save!

        assert_equal(2, page.paper_trail_versions.size, "versions")
        delete(:destroy, id: page.paper_trail_versions.first.to_param)

        assert_equal(1, page.paper_trail_versions(true).size, "versions")
      end

      test "Revert to version" do
        page = Page.create!(body: "<h1>Welcome</h1>")
        page.title = "Title"
        page.save!
        page.body = "<h1>TTYL!</h1>"
        page.save!

        get(:revert, id: page.paper_trail_versions.first.to_param)

        page.reload
        assert_equal(4, page.version, "version")
        assert_equal("<h1>Welcome</h1>", page.body, "body")
      end
    end
  end
end
