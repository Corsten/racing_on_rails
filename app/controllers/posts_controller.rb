class PostsController < ApplicationController
  def index
    @subject = params[:subject].try(:strip)
    @mailing_list = MailingList.find(params[:mailing_list_id])
    @posts = @mailing_list.posts.paginate(:page => params[:page]).order("date desc")
    if @subject.present?
      if @subject.size >= 3
        # Use select_values to find IDs without instantiating PostTexts. Arel for SQL injection protection.
        # Join instead?
        sql = PostText.select("id").where("match(text) against (?)", @subject).to_sql
        ids = PostText.connection.select_values(sql)
        @posts = @posts.where("id in (?)", ids)
      else
        flash[:notice] = "Search text must be at least three letters"
      end
    end
  end
  
  def show
    expires_in 1.hour, :public => true
    @post = Post.find(params["id"])
  end
  
  # Send email to local mail program. Don't save to database. Use mailing list's
  # archiver to store posts. This strategy gives spam filters a change to reject
  # bogus posts.
  def create
    if params[:reply_to_id].present?
      post_private_reply
    else
      post_to_list
    end
  end
  
  def post_private_reply
    @reply_to = Post.find(params[:reply_to_id])
    @post = Post.new(params[:post])
    @mailing_list = MailingList.find(@post.mailing_list_id)
    if @post.valid?
      private_reply_email = MailingListMailer.private_reply(@post, @reply_to.sender).deliver
      flash[:notice] = "Sent private reply '#{@post.subject}' to #{private_reply_email.to}"
      redirect_to mailing_list_confirm_private_reply_path(@mailing_list)
    else
      render(:action => "new", :reply_to_id => @reply_to.id)
    end
  end
  
  def post_to_list
    @post = Post.new(params[:post])
    @mailing_list = MailingList.find(@post.mailing_list_id)
    @post.mailing_list = @mailing_list
    if @post.valid?
      post_email = MailingListMailer.post(@post).deliver
      flash[:notice] = "Submitted new post: #{@post.subject}"
      redirect_to mailing_list_confirm_path(@mailing_list)
    else
      render(:action => "new")
    end
  end
  
  def new
    @mailing_list = MailingList.find(params[:mailing_list_id])
    @post = Post.new(:mailing_list => @mailing_list)
    if params[:reply_to_id].present?
      @reply_to = Post.find(params[:reply_to_id])
      @post.subject = "Re: #{@reply_to.subject}"
    end
  end
end