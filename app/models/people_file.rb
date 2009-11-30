# Excel or text file of People. Assumes that the first row is a header row. 
# Updates membership to current year. If there are no more events in the current year, updates membership to next year.
class PeopleFile < GridFile
  # TODO 'club' ...this is often team in USAC download. How handle? Use club for team if no team? and if both, ignore club?
  #    'NCCA club' ...can have this in addition to club and team. should team be many to many?

  COLUMN_MAP = {
    'team'                                   => 'team_name',
    'Cycling Team'                           => 'team_name',
    'club'                                   => 'club_name',
    'ncca club'                              => 'ncca_club_name',
    'fname'                                  => 'first_name',
    'lname'                                  => 'last_name',
    'f_name'                                 => 'first_name',
    'l_name'                                 => 'last_name',
    'FirstName'                              => 'first_name',
    'first name'                             => 'first_name',
    'LastName'                               => 'last_name',
    'last name'                              => 'last_name',
    'AAA Last Name'                          => 'last_name',
    'Birth date'                             => 'date_of_birth',
    'Birthdate'                              => 'date_of_birth',
    'year of birth'                          => 'date_of_birth',
    'dob'                                    => 'date_of_birth',
    'address'                                => 'street',
    'Address1_Contact address'               => 'street',
    'Address2_Contact address'               => 'street',
    'address1'                               => 'street',
    'City_Contact address'                   => 'city',
    'State_Contact address'                  => 'state',
    'Zip_Contact address'                    => 'zip',
    'Phone'                                  => 'home_phone',
    'DayPhone'                               => 'home_phone',
    'cell/fax'                               => 'cell_fax',
    'cell'                                   => 'cell_fax',
    'e-mail'                                 => 'email',
    'category'                               => 'road_category',
    'road cat'                               => 'road_category',
    'Cat.'                                   => 'road_category',
    'cat'                                    => 'road_category',
    'Road Category - '                       => 'road_category',
    'Road Age Group - '                      => 'road_category',
    'USCF Category'                          => 'road_category',
    'track cat'                              => 'track_category',
    'Track Category - '                      => 'track_category',
    'Track Age Group - '                     => 'track_category',
    'Cyclocross Category - '                 => 'ccx_category',
    'cross cat'                              => 'ccx_category',
    'ccx cat'                                => 'ccx_category',
    'Cyclocross Age Group -'                 => 'ccx_category',
    'Cross Country Mountain Bike Category -' => 'mtb_category',
    'mtn cat'                                => 'mtb_category',
    'Cross Country Mountain Age Group -'     => 'mtb_category',
    'XC'                                     => 'mtb_category',
    'Downhill Mountain Bike Category - '     => 'dh_category',
    'dh cat'                                 => 'dh_category',
    'dh'                                     => 'dh_category',
    'Downhill Mountain Bike Age Group -'     => 'dh_category',
    'number'                                 => 'road_number',
    '2009 road'                              => 'road_number',
    'WSBA #'                                 => 'road_number',
    '2009 xc'                                => 'xc_number',
    'mtb #'                                  => 'xc_number',
    '09 dh'                                  => 'dh_number',
    'singlespeed'                            => 'singlespeed_number',
    '2009 ss'                                => 'singlespeed_number',
    'ss'                                     => 'singlespeed_number',
    'ss #'                                   => 'singlespeed_number',
    'Membership No'                          => 'license',
    'license#'                               => 'license',
    'date joined'                            => 'member_from',
    'exp date'                               => 'member_usac_to',
    'expiration date'                        => 'member_usac_to',
    'card'                                   => 'print_card',
    'sex'                                    => 'gender',
    'What is your occupation? (optional)'    => 'occupation',
    'Suspension'                             => 'status',   #e.g. "SUSPENDED - Contact USA Cycling"
    'Interests'                              => 'notes',
    'Receipt Code'                           => 'notes',
    'Confirmation Code'                      => 'notes',
    'Transaction Payment Total'              => 'notes',
    'Registration Completion Date/Time'      => 'notes',
    'Donation'                               => 'notes',
    'Singlespeed'                            => 'notes',
    'Tandem'                                 => 'notes',
    'Please select a category:'              => Column.new(:name => 'notes', :description => 'Disciplines'),
    '2009 notes'                             => 'notes',
    'Would you like to make an additional donation to support OBRA? '                 => Column.new(:name => 'notes', :description => 'Donation'),
    'Please indicate if you are interested in racing cross country or downhill. '     => Column.new(:name => 'notes', :description => 'Downhill/Cross Country'),
    'Please indicate if you are interested in racing single speed.'                   => Column.new(:name => 'notes', :description => 'Singlespeed'),
    'Please indicate other interests. (For example: time trial tandem triathalon r'   => Column.new(:name => 'notes', :description => 'Other interests'),
    'Your team or club name (please enter N/A if you do not have a team affiliation)' => Column.new(:name => 'team_name', :description => 'Team')
  }
  
  attr_reader :created
  attr_reader :updated
  attr_reader :duplicates
  
  def initialize(source, *options)
    if options.empty?
      options = Hash.new
    else
      options = options.first
    end
    options = {
      :delimiter => ',',
      :quoted => true,
      :header_row => true,
      :row_class => Person,
      :column_map => COLUMN_MAP
    }.merge(options)

    super(source, options)

    @created = 0
    @updated = 0
    @duplicates = []
  end

  # +year+ for RaceNumbers
  # New memberships start on today, but really should start on January 1st of next year, if +year+ is next year
  def import(update_membership, year = nil)
    logger.debug("PeopleFile import update_membership: #{update_membership}")
    @update_membership = update_membership
    @has_print_column = columns.any? do |column|
      column.field == :print_card
    end
    year = year.to_i if year
    
    logger.debug("#{rows.size} rows")
    created = 0
    updated = 0
    if @update_membership
      if year && year > Date.today.year
        @member_from_imported_people = Date.new(year, 1, 1)
      else
        @member_from_imported_people = Date.today
      end
      @member_to_for_imported_people = Date.new(year || Date.today.year, 12, 31)
    end
    
    Person.transaction do
      begin
        for row in rows
          row_hash = row.to_hash
          row_hash[:year] = year if year
          row_hash[:updated_by] = "Membership import: #{import_file.name}"
          logger.debug(row_hash.inspect) if logger.debug?
          next if row_hash[:first_name].blank? && row_hash[:first_name].blank? && row_hash[:name].blank?
          
          combine_categories(row_hash)
          row_hash.delete(:date_of_birth) if row_hash[:date_of_birth] == 'xx'

          # TODO or by USAC license number
          people = Person.find_all_by_name_or_alias(:first_name => row_hash[:first_name], :last_name => row_hash[:last_name])
          person = nil
          row_hash[:member_to] = @member_to_for_imported_people if @update_membership
          if people.empty?
            delete_unwanted_member_from(row_hash, person)
            add_print_card_and_label(row_hash)
            row_hash[:created_by] = import_file
            person = Person.new(row_hash)
            person.save!
            @created = @created + 1
          elsif people.size == 1
            # Don't want to overwrite existing categories
            delete_blank_categories(row_hash)
            person = people.first
            delete_unwanted_member_from(row_hash, person)
            unless person.notes.blank?
              row_hash[:notes] = "#{people.last.notes}#{$INPUT_RECORD_SEPARATOR}#{row_hash[:notes]}"
            end
            add_print_card_and_label(row_hash, person)
            
            person = Person.update(people.last.id, row_hash)
            unless person.valid?
              raise ActiveRecord::RecordNotSaved.new(person.errors.full_messages.join(', '))
            end
            @updated = @updated + 1
          else
            logger.warn("PeopleFile Found #{people.size} people for '#{row_hash[:first_name]} #{row_hash[:last_name]}'") 
            delete_blank_categories(row_hash)
            person = Person.new(row_hash)
            delete_unwanted_member_from(row_hash, person)
            unless person.notes.blank?
              row_hash[:notes] = "#{people.last.notes}#{$INPUT_RECORD_SEPARATOR}#{row_hash[:notes]}"
            end
            add_print_card_and_label(row_hash, person)
            duplicates << Duplicate.create!(:new_attributes => row_hash, :people => people)
          end
        end
      rescue Exception => e
        logger.error("PeopleFile #{e}")
        raise
      end
    end
    return @created, @updated
  end
  
  def combine_categories(row_hash)
    for field in Person::CATEGORY_FIELDS
      row_hash[field] = row_hash[field].gsub($INPUT_RECORD_SEPARATOR, ' ') if row_hash[field]
    end
  end
  
  def delete_blank_categories(row_hash)
    for field in Person::CATEGORY_FIELDS
      row_hash.delete(field) if row_hash[field].blank?
    end
  end
  
  def delete_unwanted_member_from(row_hash, person)
    if row_hash[:member_from].blank?
      row_hash.delete(:member_from)
      return
    end
    
    unless person.nil?
      if person.member_from
        begin
          date = Date.parse(row_hash[:member_from])
          if date > person.member_from
            row_hash[:member_from] = person.member_from
          end
        rescue ArgumentError => e
          raise ArgumentError.new("#{e}: '#{row_hash[:member_from]}' is not a valid date. Row:\n #{row_hash.inspect}")
        end
      end
    end
  end
  
  def add_print_card_and_label(row_hash, person = nil)
    if @update_membership and !@has_print_column
      if person.nil? or (!person.member? or person.member_to < @member_to_for_imported_people)
        row_hash[:print_card] = true
      end
    end
  end
  
  def import_file
    unless @import_file
      if @file
        @import_file = ImportFile.create!(:name => @file.path)
      else
        @import_file = ImportFile.create!
      end
    end
    @import_file
  end
  
  def logger
    Rails.logger
  end
end