# frozen_string_literal: true

module Admin
  module Pages
    # Show old versions of Pages
    class VersionsController < Admin::AdminController
      def edit
        @version = PaperTrail::Version.find(params[:id])
        @page = @version.reify
        # The _new_ version of the old parent, which may be confusing
        parent_id = @version.last.reify.&parent_id
        @parent = Page.find(parent_id) if parent_id
      end

      def show
        @version = PaperTrail::Version.find(params[:id])
        @page = @version.versioned
        render inline: @page.body, layout: "application"
      end

      def destroy
        @version = PaperTrail::Version.find(params[:id])
        @page = @version.versioned
        @version.destroy
        flash[:notice] = "Deleted #{@page.title}"
        redirect_to edit_admin_page_path(@page)
      end

      # Revert to +version+
      def revert
        version = PaperTrail::Version.find(params[:id])
        page = version.reify
        page.save!

        expire_cache
        flash[:notice] = "Reverted #{page.title} to version from #{version.updated_at.to_s(:long)}"
        redirect_to edit_admin_page_path(page)
      end
    end
  end
end
