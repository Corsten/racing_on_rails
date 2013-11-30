module Admin
  class PostsController < Admin::AdminController
    before_filter :assign_mailing_list

    def index
      @posts = Post.
        where(:mailing_list_id => @mailing_list.id).
        order("date desc").
        page(params[:page])
    end
    
    def new
      @post = @mailing_list.posts.build
      render :edit
    end
    
    def create
      @post = @mailing_list.posts.build(post_params)
      if @post.save
        flash[:notice] = "Created #{@post.subject}"
        redirect_to edit_admin_mailing_list_post_path(@mailing_list, @post)
      else
        render :edit
      end
    end
    
    def receive
      @post = MailingListMailer.receive(params[:raw].read.encode("UTF-8"))
      if @post.save
        flash[:notice] = "Created #{@post.subject}"
        redirect_to admin_mailing_list_posts_path(@mailing_list)
      else
        render :edit
      end
    end
    
    def edit
      @post = Post.find(params[:id])
    end
    
    def update
      @post = Post.find(params[:id])
      if @post.update_attributes(post_params)
        flash[:notice] = "Updated #{@post.subject}"
        redirect_to edit_admin_mailing_list_post_path(@mailing_list, @post)
      else
        render :edit
      end
    end
    
    def destroy
      @post = Post.find(params[:id])
      unless @post.destroy
        flash[:notice] = "Could not delete #{@post.subject}"
      end
      redirect_to admin_mailing_list_posts_path(@mailing_list)
    end


    private

    def post_params
      params.require(:post).permit(:body, :date, :from_name, :from_email_address, :path, :sender, :subject, :title)
    end

    def assign_mailing_list
      @mailing_list = MailingList.find(params[:mailing_list_id])
    end
  end
end
