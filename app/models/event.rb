# Superclass for anything that can have results:
# * Event (Superclass only used to organizes multiple sets of results on a single day.
#          Examples: Alpenrose Challenge Morning Session, Alpenrose Challenge Afternoon Session)
# * SingleDayEvent (Most events, an event on a particular date. Appears on calendar.)
# * MultiDayEvent (Spans more than one day. has many SingleDayEvent children)
# * Competition (Results are calculated/derived from other events' results. Examples: Combined TT times, OBRA BAR)
#
# instructional: class or clinc
# practice: training session
#
# Events have four similar, but distinct relationships to other Events:
# * parent-children: A one-to-many tree. Example: stage race parent + stages children.
#   Used for calculating competition results and schedule display. Does _not_ include
#   Competitions, even though Competitions can have Event parents.
#
#   A purer children association would return all child Events and Competitions
#  (that's how they are in the database). But we almost always want just the child Events,
#   and not the Competitions.
#   
# * parent-child_competitions: A one-to-many tree. Example: stage race MultiDayEvent parent
#   with GC and KOM child_competitions. Typically combined with children when we really
#   do want all child Competitions and Events.
#
# * competition_event_memberships: many-to-many from Events to Competitions. Example: Banana Belt I
#   can be a member of the Oregon Cup and the OBRA Road BAR. And the Oregon Cup also includes Kings Valley RR,
#   Table Rock RR, etc. CompetitionEventMembership is a meaningul class in its own right.
class Event < ActiveRecord::Base
  PROPOGATED_ATTRIBUTES = %w{
    city discipline flyer name number_issuer_id promoter_id prize_list sanctioned_by state time velodrome_id time
    cancelled flyer_approved instructional practice sanctioned_by 
  } unless defined?(PROPOGATED_ATTRIBUTES)

  before_validation :find_associated_records
  before_destroy :validate_no_results

  validates_presence_of :name, :date, :discipline
  validate :parent_is_not_self

  belongs_to :parent, :foreign_key => "parent_id", :class_name => "Event"
  has_many :children,
           :class_name => "Event",
           :foreign_key => "parent_id",
           :dependent => :destroy,
           :conditions => "type is null or type = 'SingleDayEvent'", 
           :order => "date",
           :after_add => :children_changed,
           :after_remove => :children_changed

  has_many :child_competitions,
           :class_name => "Competition",
           :foreign_key => "parent_id",
           :dependent => :destroy,
           :conditions => "type is not null and type != 'SingleDayEvent'", 
           :order => "date",
           :after_add => :children_changed,
           :after_remove => :children_changed 

  has_many :children_and_child_competitions,
           :class_name => "Event",
           :foreign_key => "parent_id",
           :dependent => :destroy,
           :order => "date"

  has_one :overall, :foreign_key => "parent_id", :dependent => :destroy
  has_one :combined_results, :class_name => "CombinedTimeTrialResults", :foreign_key => "parent_id", :dependent => :destroy
  has_many :competitions, :through => :competition_event_memberships, :source => :competition
  has_many :competition_event_memberships

  belongs_to :number_issuer
  belongs_to :promoter, :foreign_key => "promoter_id"
  belongs_to :team

  has_many   :races,
             :dependent => :destroy,
             :after_add => :children_changed,
             :after_remove => :children_changed 

  belongs_to :velodrome

  include Comparable

  # Return list of every year that has at least one event
  def Event.find_all_years
    years = []
    results = connection.select_all(
      "select distinct extract(year from date) as year from events"
    )
    results.each do |year|
      years << year.values.first.to_i
    end
    years.sort.reverse
  end
  
  # Used when importing Racers: should membership be for this year or the next?
  def Event.find_max_date_for_current_year
    # TODO Make this better
    maximum(:date, :conditions => ['date > ? and date < ?', Date.new(Date.today.year, 1, 1), Date.new(Date.today.year + 1, 1, 1)])
  end
  
  def Event.friendly_class_name
    name.underscore.humanize.titleize
  end

  def after_initialize
    set_defaults
  end
    
  # Defaults state to ASSOCIATION.state, date to today, name to New Event mm-dd-yyyy
  # NumberIssuer: ASSOCIATION.short_name
  # Child events use their parent's values unless explicity override. And you cannot override
  # parent values by passing in blank or nil attributes to initialize, as there is
  # no way to differentiate missing values from nils or blanks.
  def set_defaults
    if new_record?
      if parent
        PROPOGATED_ATTRIBUTES.each { |attr| 
          (self[attr] = parent[attr]) if self[attr].nil? 
        }
      end
      self.bar_points = default_bar_points       if self[:bar_points].nil?
      self.date = default_date                   if self[:date].nil?
      self.discipline = default_discipline       if self[:discipline].nil?
      self.name = default_name                   if self[:name].nil?
      self.ironman = default_ironman             if self[:ironman].nil?
      self.number_issuer = default_number_issuer if number_issuer.nil?
      self.sanctioned_by = default_sanctioned_by if self[:sanctioned_by].blank?
      self.state = default_state                 if self[:state].blank?
      self.sanctioned_by = default_sanctioned_by if (parent.nil? && self[:sanctioned_by].nil?) || (parent && parent[:sanctioned_by].nil?)
      self.state = default_state                 if (parent.nil? && self[:state].nil?) || (parent && parent[:state].nil?)
    end
  end
  
  def default_bar_points
    1
  end
  
  def default_date
    if parent.present?
      parent.date
    else
      Date.today
    end
  end
  
  def default_discipline
    "Road"
  end
  
  def default_ironman
    1
  end
  
  def default_name
    "New Event #{self.date.strftime("%m-%d-%Y")}"
  end
  
  def default_state
    ASSOCIATION.state
  end
  
  def default_sanctioned_by
    ASSOCIATION.default_sanctioned_by
  end
  
  def default_number_issuer
    NumberIssuer.find_by_name(ASSOCIATION.short_name)
  end
  
  # TODO Could be replaced with a select join if too slow
  # TODO Use has_results?
  def validate_no_results
    races(true).each do |race|
      if !race.results(true).empty?
        errors.add('results', 'Cannot destroy event with results')
        return false 
      end
    end

    children(true).each do |event|
      errors.add('results', 'Cannot destroy event with children with results')
      return false unless event.validate_no_results
    end

    true
  end
  
  # Will return false-positive if there are only overall series results, but those should only exist if there _are_ "real" results.
  # The results page should show the results in that case.
  def has_results?(reload = false)
    self.races(reload).any? { |r| !r.results(reload).empty? }
  end
  
  # Will return false-positive if there are only overall series results, but those should only exist if there _are_ "real" results.
  # The results page should show the results in that case.
  def has_results_including_children?(reload = false)
    self.races(reload).any? { |r| !r.results(reload).empty? } || children(reload).any? { |event| event.has_results? }
  end
  
  # Returns only the children with +results+
  def children_with_results(reload = false)
    children(reload).select(&:has_results?)
  end
  
  # Returns only the children and child child_competitions with +results+
  def children_and_child_competitions_with_results(reload = false)
    children_and_child_competitions(reload).select(&:has_results?)
  end
  
  # Returns only the Races with +results+
  def races_with_results
    races.select { |race| !race.results.empty? }.sort
  end

  def destroy_races
    disable_notification!
    self.races.clear
    enable_notification!
  end

  # TODO Remove. Old workaround to ensure children are cancelled
  def find_associated_records
    existing_discipline = Discipline.find_via_alias(discipline)
    self.discipline = existing_discipline.name unless existing_discipline.nil?
  
    if promoter
      if promoter.name.blank? && promoter.email.blank? && promoter.phone.blank?
        self.promoter = nil
      else
        existing_promoter = Promoter.find_by_info(promoter.name, promoter.email, promoter.phone)
        if existing_promoter
          self.promoter = existing_promoter
        end
      end
    end
  end
  
  # Update child events from parents' attributes if child attribute has the
  # same value as the parent before update
  def update_children
    return true if new_record? || children.count == 0
    changes.select { |key, value| PROPOGATED_ATTRIBUTES.include?(key) }.each do |change|
      attribute = change.first
      was = change.last.first
      if was
        SingleDayEvent.update_all(["#{attribute}=?", self[attribute]], ["#{attribute}=? and parent_id=?", was, self[:id]])
      else
        SingleDayEvent.update_all(["#{attribute}=?", self[attribute]], ["(#{attribute}=? or #{attribute} is null) and parent_id=?", was, self[:id]])
      end
    end
    
    children.each { |child| child.update_children }
    true
  end

  def children_changed(child)
    # Don't trigger callbacks
    Event.update_all(["updated_at = ?", Time.now], ["id = ?", id])
    true
  end
  
  # Update database immediately with save!
  def disable_notification!
    if notification_enabled?
      ActiveRecord::Base.lock_optimistically = false
      # Don't trigger after_save callback just because we're enabling notification
      self.notification = false
      Event.update_all("notification = false", ["id = ?", id])
      children.each(&:disable_notification!)
      ActiveRecord::Base.lock_optimistically = true
    end
    false
  end

  # Update database immediately with save!
  def enable_notification!
    unless notification_enabled?
      ActiveRecord::Base.lock_optimistically = false
      # Don't trigger after_save callback just because we're enabling notification
      self.notification = true
      Event.update_all("notification = true", ["id = ?", id])
      children.each(&:enable_notification!)
      ActiveRecord::Base.lock_optimistically = true
    end
    true
  end

  # Child results fire change notifications? Set to false before bulk changes 
  # like event results import to prevent many pointless change notifications
  # and CombinedTimeTrialResults recalcs
  # Check database to ensure most recent value is used, and not a association's out-of-date cached value
  def notification_enabled?
    connection.select_value("select notification from events where id = #{id}") == "1"
  end

  # Set point value/factor for this Competition. Convenience method to hide CompetitionEventMembership complexity.
  def set_points_for(competition, points)
    # For now, allow Nil exception, but probably will want to auto-create membership in the future
    competition_event_membership = competition_event_memberships.detect { |cem| cem.competition == competition }
    competition_event_membership.points_factor = points
    competition_event_membership.save!
  end

  # Format for schedule page primarily
  # TODO is this used?
  def short_date
    return '' unless date
    prefix = ' ' if date.month < 10
    suffix = ' ' if date.day < 10
    "#{prefix}#{date.month}/#{date.day}#{suffix}"
  end

  # +date+
  def start_date
    date
  end
  
  def start_date=(date)
    self.date = date
  end
  
  def end_date
    if !children(true).empty?
      children.last.date
    else
      start_date
    end
  end
  
  def year
    return nil unless date
    date.year
  end

  def multiple_days?
    end_date > start_date
  end
  
  def city_state
    if !city.blank?
      if !state.blank?
        "#{city}, #{state}"
      else
        city
      end
    else
      if !state.blank?
        state
      else
        ''
      end
    end
  end
  
  def location
    self.city_state
  end

  def discipline_id
    Discipline[discipline].id if Discipline[discipline]
  end
  
  def flyer
    unless self[:flyer].blank?
      if self[:flyer][/^\//]
        return 'http://' + STATIC_HOST + self[:flyer]
      elsif self[:flyer][/^..\/..\//]
        return 'http://' + STATIC_HOST + (self[:flyer][/^..\/..(.*)/, 1])
      end
    end
    self[:flyer]
  end
  
  def promoter_name
    promoter.name if promoter
  end

  def promoter_name=(value)
    if promoter.nil?
      self.promoter = Promoter.new
    end
    self.promoter.name = value
  end

  def promoter_email
    promoter.email if promoter
  end

  def promoter_email=(value)
    if promoter.nil?
      self.promoter = Promoter.new
    end
    self.promoter.email = value
  end

  def promoter_phone
    promoter.phone if promoter
  end

  def promoter_phone=(value)
    if promoter.nil?
      self.promoter = Promoter.new
    end
    self.promoter.phone = value
  end

  def date_range_s(format = :short)
    if format == :long
      date.strftime('%m/%d/%Y')
    else
      "#{date.month}/#{date.day}"
    end
  end

  def date_range_long_s
    date.strftime('%a, %B %d')
  end
  
  # Parent's name. Own name if no parent
  def parent_name
    if parent.nil?
      name
    else
      parent.name
    end
  end
  
  def full_name
    if parent.nil?
      name
    elsif parent.full_name == name
      name
    elsif name[parent.full_name]
      name
    else
      "#{parent.full_name}: #{name}"
    end
  end


  # Only SingleDayEvent subclass has a parent -- this abstract class, Event, does not have a
  # parent, but implementing missing_parent? here allows clients to just call the method
  # without first checking that it exists
  def missing_parent?
    false
  end

  # Only MultiDayEvent subclass has children -- this abstract class, Event, does not have 
  # children, but implementing missing_children? here allows clients to just call the method
  # without first checking that it exists
  def missing_children?
    !missing_children.empty?
  end
  
  # Only MultiDayEvent subclass has children -- this abstract class, Event, does not have 
  # children, but implementing missing_children? here allows clients to just call the method
  # without first checking that it exists
  def missing_children
    []
  end
  
  def multi_day_event_children_with_no_parent?
    !multi_day_event_children_with_no_parent.empty?
  end
  
  def multi_day_event_children_with_no_parent
    return [] unless name && date
    
    @multi_day_event_children_with_no_parent ||= SingleDayEvent.find(
      :all, 
      :conditions => [
        "parent_id is null and name = ? and extract(year from date) = ? 
         and ((select count(*) from events where name = ? and extract(year from date) = ? and type in ('MultiDayEvent', 'Series', 'WeeklySeries')) = 0)",
         self.name, self.date.year, self.name, self.date.year])
    # Could do this in SQL
    if @multi_day_event_children_with_no_parent.size == 1
      @multi_day_event_children_with_no_parent = []
    end
    @multi_day_event_children_with_no_parent
  end

  #mbrahere: I added has_children?
  def has_children?
    if Event.count(:conditions => "parent_id = #{self.id}") > 0
      true
    else
      false
    end
  end

  def missing_parent
    nil
  end
  
  # TODO Use acts as tree
  def root
    node = self
    node = node.parent while node.parent
    node
  end

  def ancestors
    node, nodes = self, []
    nodes << node = node.parent while node.parent
    nodes
  end

  def parent_is_not_self
    if parent_id && parent_id == id
      errors.add("parent", "Event cannot be its own parent")
    end
  end

  def friendly_class_name
    self.class.friendly_class_name
  end
  
  def <=>(other)
    return -1 if other.nil?
    
    return 0 if id == other.id
    
    if date && other.date
      date <=> other.date
    else
      0
    end 
  end
  
  def inspect_debug
    puts("#{self.class.name.ljust(20)} #{self.date} #{self.name} #{self.discipline} #{self.id}")
    self.races(true).each {|r| 
      puts("#{r.class.name.ljust(20)}   #{r.name}")
      r.results(true).sort.each {|result|
        puts("#{result.class.name.ljust(20)}      #{result.to_long_s}")
        result.scores(true).each{|score|
          puts("#{score.class.name.ljust(20)}         #{score.source_result.place} #{score.source_result.race.event.name}  #{score.source_result.race.name} #{score.points}")
        }
      }
    }
    
    self.children(true).each do |event|
      event.inspect_debug
    end
    
    ""
  end

  def to_s
    "<#{self.class} #{id} #{discipline} #{name} #{date}>"
  end
end
