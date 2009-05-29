require "spreadsheet"

# Result time limited to hundredths of seconds
#
# TODO improve naming. Attribute keys? Hash keys?
# TODO Ensure blank rows aren't processed
#
# Notes example:
# Senior Men Pro 1/2 | Field size: 79 riders | Laps: 2
class ResultsFile
  attr_accessor :columns
  attr_accessor :column_indexes
  attr_accessor :event
  attr_accessor :invalid_columns
  attr_accessor :rows
  attr_accessor :source

  COLUMN_MAP = {
    "placing"          => "place",
    "#"                => "number",
    "wsba#"            => "number",
    "rider_#"          => "number",
    'racing_age'       => 'age',
    "barcategory"      => "parent",
    "bar_category"     => "parent",
    "category.name"    => "category_name",
    "categories"       => "category_name",
    "category"         => "category_name",
    "cat."             => "category_name",
    "first"            => "first_name",
    "firstname"        => "first_name",
    "racer.first_name" => "first_name",
    "racer"            => "name",
    "last"             => "last_name",
    "lastname"         => "last_name",
    "racer.last_name"  => "last_name",
    "team"             => "team_name",
    "team.name"        => "team_name",
    "obra_number"      => "number",
    "oregoncup"        => "oregon_cup",
    "membership_#"     => "license",
    "membership"       => "license",
    "club/team"        => "team_name",
    "hometown"         => 'city',
    "stage_time"       => "time",
    "st"               => "time",
    "stop_time"        => "time",
    "bonus"            => "time_bonus_penalty",
    "penalty"          => "time_bonus_penalty",
    "stage_+_penalty"  => "time_total",
    "time"             => "time",
    "time_total"       => "time_total",
    "total_time"       => "time_total",
    "down"             => "time_gap_to_leader",
    "gap"              => "time_gap_to_leader",
    "pts"              => "points",
    "sex"              => "gender"
  }

  # Toggle expensive debug logging
  DEBUG = false
  
  def initialize(source, event)
    self.column_indexes = nil
    self.event = event
    self.invalid_columns = []
    self.source = source
  end

  def import
    Rails.logger.info("ResultsFile #{Time.now} import")

    Event.transaction do
      event.disable_notification!
      book = Spreadsheet.open(source.path)
      book.worksheets.each do |worksheet|
        race = nil
        create_rows(worksheet)

        rows.each do |row|
          Rails.logger.debug("ResultsFile #{Time.now} row #{row.spreadsheet_row.to_a.join(', ')}") if DEBUG && Rails.logger.debug?
          if race?(row)
            race = create_race(row)
          elsif result?(row)
            create_result(row, race)
          end
        end
      end
      event.enable_notification!
      CombinedTimeTrialResults.create_or_destroy_for!(event)
    end
    Rails.logger.info("ResultsFile #{Time.now} import done")
  end

  def create_rows(worksheet)
    # Need all rows. Decorate them before inspecting them.
    # Drop empty ones
    self.rows = []
    previous_row = nil
    worksheet.each do |spreadsheet_row|
      if DEBUG && Rails.logger.debug?
        Rails.logger.debug("ResultsFile #{Time.now} row #{spreadsheet_row.to_a.join(', ')}")
        spreadsheet_row.each_with_index do |cell, index|
          Rails.logger.debug("number_format pattern to_s to_f #{spreadsheet_row.format(index).number_format}  #{spreadsheet_row.format(index).pattern} #{cell.to_s} #{cell.to_f if cell.respond_to?(:to_f)} #{cell.class}")
        end
      end
      row = ResultsFile::Row.new(spreadsheet_row, column_indexes)
      unless row.blank?
        if column_indexes.nil?
          create_columns(spreadsheet_row)
        else
          row.previous = previous_row
          previous_row.next = row if previous_row
          rows << row
          previous_row = row
        end
      end
    end
  end
  
  # Create Hash of normalized column name indexes
  # Convert column names to lowercase and underscore. Use COLUMN_MAP to normalize.
  #
  # Example:
  # Place, Num, First Name
  # { :place => 0, :number => 1, :first_name => 2 }
  def create_columns(spreadsheet_row)
    self.column_indexes = Hash.new
    self.columns = []
    spreadsheet_row.each_with_index do |cell, index|
      cell_string = cell.to_s
      if index == 0 && cell_string.blank?
        column_indexes[:place] = 0
      elsif !cell_string.blank?
        cell_string.strip!
        cell_string.gsub!(/^"/, '')
        cell_string.gsub!(/"$/, '')
        cell_string = cell_string.downcase.underscore
        cell_string.gsub!(" ", "_")
        cell_string = COLUMN_MAP[cell_string] if COLUMN_MAP[cell_string]
        if !cell_string.blank?
          if Race::RESULT.respond_to?(cell_string.to_sym)
            self.column_indexes[cell_string.to_sym] = index
            self.columns << cell_string 
          else
            self.invalid_columns << cell.to_s
          end
        end
      end
    end
    
    Rails.logger.debug("ResultsFile #{Time.now} Create column indexes #{self.column_indexes.inspect}") if DEBUG && Rails.logger.debug?
    self.column_indexes
  end

  def race?(row)
    return false if column_indexes.nil? || row.last? || row.blank? || (row.next && row.next.blank?)
    return false if row.place && row.place.to_i != 0
    row.next && row.next.place && row.next.place.to_i == 1
  end

  def create_race(row)
    category = Category.find_or_create_by_name(row.first)
    race = event.races.build(:category => category, :notes => row.notes)
    race.result_columns = columns
    race.save!
    Rails.logger.info("ResultsFile #{Time.now} create race #{category}")
    race
  end

  def result?(row)
    return false unless column_indexes
    return false if row.blank?
    return true if !row.place.blank?
    return true if !row[:number].blank?
    return true if !row[:license].blank?
    if !row[:team_name].blank?
      return true
    end
    if !(row[:first_name].blank? && row[:last_name].blank? && row[:name].blank?)
      return true
    end
    false
  end

  def create_result(row, race)
    if race
      result = race.results.build(row.to_hash)
      result.updated_by = @event.name

      if row[:time] && (row[:time].to_s.downcase.include?("st") || row[:time].to_s.downcase.include?("s.t."))
        result.time = row.previous.result.time
      end

      if result.place.to_i > 0
        result.place = result.place.to_i
      elsif !result.place.blank?
        result.place = result.place.upcase rescue result.place
      elsif !row.previous[:place].blank? && row.previous[:place].to_i == 0
        result.place = row.previous[:place]
      end

      result.cleanup
      result.save!
      row.result = result
      Rails.logger.debug("ResultsFile #{Time.now} create result #{race} #{result.place}") if DEBUG && Rails.logger.debug?
    else
      # TODO Maybe a hard exception or error would be better?
      Rails.logger.warn("No race. Skip.")
    end
  end

  # TODO Try caching some things
  class Row
    attr_reader :column_indexes
    attr_accessor :next
    attr_accessor :previous
    attr_accessor :result
    attr_reader :spreadsheet_row

    def initialize(spreadsheet_row, column_indexes)
      @spreadsheet_row = spreadsheet_row
      @column_indexes = column_indexes
    end

    def [](column_symbol)
      index = column_indexes[column_symbol]
      if index
        value = spreadsheet_row[index]
        value = spreadsheet_row[index].value if spreadsheet_row[index].is_a?(Spreadsheet::Formula)
        value.strip! if value.respond_to?(:strip!)
        value
      end
    end

    def to_hash
      hash = Hash.new
      column_indexes.keys.each { |key| hash[key] = self[key] }
      hash
    end

    def blank?
      spreadsheet_row.all? { |cell| cell.to_s.blank? }
    end

    def first
      spreadsheet_row[0]
    end

    def first?
      spreadsheet_row.idx == 0
    end

    def last?
      spreadsheet_row == spreadsheet_row.worksheet.last_row
    end

    def size
      spreadsheet_row.size
    end
    
    def place
      if column_indexes[:place]
        value = self[:place]
      else
        value = spreadsheet_row[0]
        value = spreadsheet_row[0].value if spreadsheet_row[0].is_a?(Spreadsheet::Formula)
        value.strip! if value.respond_to?(:strip!)
      end

      # Mainly to handle Dates and DateTimes in the place column
      value = nil unless value.respond_to?(:to_i)
      value
    end

    def notes
      return "" if blank? || size < 2
      spreadsheet_row[1, size - 1].select { |cell| !cell.blank? }.join(", ")
    end
    
    def to_s
      "#<ResultsFile::Row #{spreadsheet_row.to_a.join(', ')} >"
    end
  end
end
