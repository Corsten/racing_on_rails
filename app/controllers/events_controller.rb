class EventsController < ApplicationController
  include Api::Events
  
  # HTML: Event dashboard for promoter (Person)
  # XML, JSON: Remote API
  # == Params
  # * person_id
  #
  # == Returns
  # JSON and XML results are paginated with a page size of 10
  # * event: [ :id, :parent_id, :name, :type, :discipline, :city, :cancelled, :beginner_friendly ]
  # * race: [ :id, :distance, :city, :state, :laps, :field_size, :time, :finishers, :notes ]
  # * category: [ :id, :name, :ages_begin, :ages_end, :friendly_param ]
  #
  # See source code of API::Base
  def index
    respond_to do |format|
      format.html {
        if params[:person_id]
          @person = Person.find(params[:person_id])
          @events = @person.events.find(
                      :all, 
                      :conditions => [ "date between ? and ?", ASSOCIATION.effective_today.beginning_of_year, ASSOCIATION.effective_today.end_of_year ])
        else
          redirect_to schedule_path
        end
      }
      format.xml { render :xml => events_as_xml }
      format.json { render :json => events_as_json }
    end
  end
end
