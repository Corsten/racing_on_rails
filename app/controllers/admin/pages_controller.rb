# Admin editing for Pages in built-in CMS. All editing actions expire the cache.
class Admin::PagesController < Admin::AdminController
  before_filter :require_administrator, :except => [ :show ]
  in_place_edit_for :page, :title
  layout "admin/application"

  def index
    @pages = Page.roots
  end
  
  def new
    @page = Page.new(params[:page])
    render(:edit)
  end
  
  def create
    @page = Page.new(params["page"])
    @page.author = current_person
    @page.save
    if @page.errors.empty?
      flash[:notice] = "Created #{@page.title}"
      expire_cache
      redirect_to(edit_admin_page_path(@page))
    else
      render(:edit)
    end
  end
  
  def edit
    @page = Page.find(params[:id])
  end
  
  def update
    @page = Page.find(params[:id])
    @page.author = current_person
    if @page.update_attributes(params[:page])
      flash[:notice] = "Updated #{@page.title}"
      expire_cache
      redirect_to(edit_admin_page_path(@page))
    else
      render(:action => :edit)
    end
  end
  
  def destroy
    @page = Page.find(params[:id])
    begin
      ActiveRecord::Base.lock_optimistically = false
      @page.destroy
    ensure
      ActiveRecord::Base.lock_optimistically = true
    end
    
    expire_cache
    flash[:notice] = "Deleted #{@page.title}"
    redirect_to admin_pages_path
  end
end
