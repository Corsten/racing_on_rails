# Homepage
class HomeController < ApplicationController
  caches_page :index
        
  # Show homepage
  # === Assigns
  # * upcoming_events: instance of UpcomingEvents with default parameters
  # * recent_results: Events with Results within last two weeks
  def index
    @upcoming_events = UpcomingEvents.find_all(:weeks => 5)
    
    cutoff = Date.today - 14
    
    @recent_results = Event.find(:all,
      :select => "DISTINCT(events.id), events.name, events.parent_id, events.date, events.sanctioned_by",
      :joins => [:races => :results],
      :conditions => [
        'events.type is not null and events.type != ? and events.date > ? and events.sanctioned_by = ?',
        "CombinedTimeTrialResults", cutoff, ASSOCIATION.short_name
      ],
      :order => 'events.date desc'
    )

    render_page  
  end
  
  def auction
    @bid = Bid.highest
    render(:partial => 'auction')
  end
  
  def bid
    @highest_bid = Bid.highest
    @bid = Bid.new
  end
  
  def send_bid
    @bid = Bid.create(params[:bid])
    if @bid.errors.empty?
      begin
        BidMailer.create_created(@bid)
      rescue Exception => e
        logger.error("Could not send bid email notification: #{e}")
      end
      redirect_to :action => 'confirm_bid'
    else
      @highest_bid = Bid.highest
      render(:action => 'bid')
    end
  end
end
