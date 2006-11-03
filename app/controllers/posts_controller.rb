class PostsController < ApplicationController

  model :post

  session :only => [:show, :post, :confirm]
  
  def index
    mailing_list_name = params["mailing_list_name"]
    month_start = Time.now.beginning_of_month
    redirect_to(
      :action => "list", 
      :controller => "posts",
      :month => month_start.month, 
      :year => month_start.year, 
      :mailing_list_name => mailing_list_name
    )
  end

  def list
    # Could do SQL join instead, but paginate doesn't play nice or secure
    mailing_list_name = params["mailing_list_name"]
    @mailing_list = MailingList.find_by_name(mailing_list_name)
    
    requested_year = params["year"]
    requested_month = params["month"]
    if requested_year and requested_month
      month_start = Time.local(requested_year.to_i, requested_month.to_i, 1)
    end
    
    if params["previous"]
      month_start = month_start.months_ago(1)
      return redirect_to(:year => month_start.year, :month => month_start.month)
    elsif params["next"]
      month_start = month_start.next_month
      return redirect_to(:year => month_start.year, :month => month_start.month)
    end
    
    # end_of_month sets to 00:00
    month_end = month_start.end_of_month.change(:hour => 23, :min => 59, :sec => 59, :usec => 999999)
    @year = month_start.year
    @month = month_start.month
    
    @posts = Post.find_for_dates(@mailing_list, month_start, month_end)
  end
  
  def show
    if params["previous"]
      return redirect_to(:id => params["previous_id"])
    elsif params["next"]
      return redirect_to(:id => params["next_id"])
    end
    @post = Post.find(params["id"])
  end
  
  # Send email to local mail program. Don't save to database. Use mailing list's
  # archiver to store posts. This strategy gives spam filters a change to reject
  # bogus posts.
  def post
    if params[:reply_to][:id].blank?
      post_to_list
    else
      post_private_reply
    end
  end
  
  def post_private_reply
    @reply_to = Post.find(params[:reply_to][:id])
    @private_reply = Post.new(params[:mailing_list_post])
    if @private_reply.valid?
      private_reply_email = MailingListMailer.create_private_reply(@private_reply, @reply_to.sender)
      MailingListMailer.deliver(private_reply_email)
      flash[:notice] = "Sent private reply '#{@private_reply.subject}' to #{private_reply_email.to}"
      redirect_to(:action => "confirm_private_reply", :mailing_list_name => params[:mailing_list_name])
    else
      render(:action => "new", :reply_to => @reply_to.id)
    end
  end
  
  def post_to_list
    @mailing_list_post = Post.new(params[:mailing_list_post])
    @mailing_list = MailingList.find(@mailing_list_post.mailing_list_id)
    @mailing_list_post.mailing_list = @mailing_list
    if @mailing_list_post.valid?
      post_email = MailingListMailer.create_post(@mailing_list_post)
      MailingListMailer.deliver(post_email)
      flash[:notice] = "Submitted new post: #{@mailing_list_post.subject}"
      redirect_to(:action => "confirm", :mailing_list_name => @mailing_list.name)
    else
      render(:action => "new")
    end
  end
  
  def new
    mailing_list_name = params["mailing_list_name"]
    @mailing_list = MailingList.find_by_name(mailing_list_name)
    @mailing_list_post = Post.new(:mailing_list => @mailing_list)
    reply_to_id = params[:reply_to]
    if reply_to_id
      @reply_to = Post.find(reply_to_id)
      @mailing_list_post.subject = "Re: #{@reply_to.subject}"
    end
  end
  
  def confirm
    mailing_list_name = params["mailing_list_name"]
    @mailing_list = MailingList.find_by_name(mailing_list_name)
  end
  
  def confirm_private_reply
    mailing_list_name = params["mailing_list_name"]
    @mailing_list = MailingList.find_by_name(mailing_list_name)
  end
end