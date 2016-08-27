require "categories"

# Senior Men, Pro/1/2, Novice Masters 45+
#
# Categories are just a simple hierarchy of names
#
# Categories are basically labels and there is no complex hierarchy. In other words, Senior Men Pro/1/2 and
# Pro/1/2 are two distinct categories. They are not combinations of Pro and Senior and Men and Cat 1
#
# +friendly_param+ is used for friendly links on BAR pages. Example: senior_men
class Category < ActiveRecord::Base
  acts_as_tree
  include ActsAsTree::Validation

  include Categories::Ability
  include Categories::Ages
  include Categories::Cleanup
  include Categories::Equipment
  include Comparable
  include Categories::FriendlyParam
  include Categories::Gender
  include Categories::NameNormalization
  include Categories::Weight
  include Export::Categories

  acts_as_list

  has_many :results
  has_many :races

  before_validation :set_friendly_param

  validates_presence_of :name
  validates_presence_of :friendly_param

  scope :same, lambda { |category|
    query = Category.all
    query = query.where(ability_begin: category.ability_range)
    query = query.where(ages_begin: category.ages)
    query = query.where(equipment: category.equipment)
    query = query.where(gender: category.gender)
    query = query.where(weight: category.weight)

    query
  }

  def include?(other_category)
    other_category.ability_begin >= ability_begin &&
    other_category.ability_begin <= ability_end &&
    other_category.ages_begin >= ages_begin &&
    other_category.ages_begin <= ages_end &&
    (equipment.nil? || equipment == other_category.equipment) &&
    (gender == "M" || other_category.gender == "F")
  end

  def differences(other_category)
    differences = []

    if ability_range != other_category.ability_range
      differences << :ability
    end

    if ages != other_category.ages
      differences << :ages
    end

    if equipment != other_category.equipment
      differences << :equipment
    end

    if gender != other_category.gender
      differences << :gender
    end

    differences
  end

  scope :different, lambda { |category, other_category|
    query = Category.all

    differences = category.differences(other_category)

    if category.include?(other_category)
      if differences == [ :ability ]
        query = query.where.not(ability_begin: other_category.ability_range)
      end

      if differences == [ :ages ]
        query = query.where.not(ages_begin: other_category.ages)
      end
    end

    # if category.include?(other_category)
    #   differences = category.differences(other_category)
    #
    #   if differences.include?(:ability) && category.all_abilities?
    #     query = query.where.not(ability_begin: other_category.ability_range)
    #   end
    #
    #   if differences.include?(:ages) && category.all_ages?
    #     query = query.where.not(ages_begin: other_category.ages)
    #   end
    #
    #   if differences.include?(:gender) && category.all_genders?
    #     query = query.where.not(gender: other_category.gender)
    #   end
    #
    #   if differences.include?(:equipment) && all_equipment?
    #     query = query.where.not(equipment: other_category.equipment)
    #   end
    # end

    query
  }

  def ability?
    ability_range != (0..::Categories::MAXIMUM)
  end

  def ages?
    ages != (0..::Categories::MAXIMUM)
  end

  def all_abilities?
    ability_range == (0..::Categories::MAXIMUM)
  end

  def all_ages?
    ages == (0..::Categories::MAXIMUM)
  end

  def all_equipment?
    equipment.nil?
  end

  def all_genders?
    gender == "M"
  end

  def all_weights?
    weight.nil?
  end

  def gender?
    gender != "M"
  end

  scope :within_old, lambda { |race|
    # TODO match by ages for masters
    # TODO all_ages? all_juniors?
    # TODO Need to handle these as overlapping ranges in different tracks: junior, masters, equipment
    # TODO USe betweeen
    # TODO handle no groups
    # TODO other_event_categories should be a method?

    # What groups does a category have?
    # * ability + gender: cat 3 Men, cat 3 women (gender becasue there are two cats with same ability and different genders)
    # * gender: senior Men
    # * age + gender: junior men, jr Women
    # * equipment: singlespeed
    # * weight: Clydesdale

    within = same(race.category)

    other_event_categories = race.event.categories.reject { |category| category == race.category }

    other_event_categories.each do |category|
      within = within.different(race.category, category)
    end

    within
  }

  # All categories with no parent (except root 'association' category)
  def self.find_all_unknowns
   Category.includes(:children).where(parent_id: nil).where("name != ?", RacingAssociation.current.short_name)
  end

  # Sr, Mst, Jr, Cat, Beg, Exp
  def self.short_name(name)
    return name if name.blank?
    name.gsub('Senior', 'Sr').gsub('Masters', 'Mst').gsub('Junior', 'Jr').gsub('Category', 'Cat').gsub('Beginner', 'Beg').gsub('Expert', 'Exp').gsub("Clydesdale", "Clyd")
  end

  # Need to iterate until there is a unique match
  # weight
  # equipment
  # age
  # gender
  # ability
  # Not really in? but best match
  def in?(race)
    p ""
    p "#{self.name} in? #{race.name}"

    return true if race.category == self

    matching_categories = race.event.categories.select { |category| weight == category.weight }
    p "weight: #{matching_categories.map(&:name).join(', ')}"
    return true if matching_categories.one? && matching_categories.first == race.category
    return false if matching_categories.one? && matching_categories.first != race.category
    return false if matching_categories.none?

    matching_categories = matching_categories.select { |category| equipment == category.equipment }
    p "equipment: #{matching_categories.map(&:name).join(', ')}"
    return true if matching_categories.one? && matching_categories.first == race.category
    return false if matching_categories.one? && matching_categories.first != race.category
    return false if matching_categories.none?

    matching_categories = matching_categories.select { |category| ages_begin.in?(category.ages) }
    p "ages: #{matching_categories.map(&:name).join(', ')}"
    return true if matching_categories.one? && matching_categories.first == race.category
    return false if matching_categories.one? && matching_categories.first != race.category
    return false if matching_categories.none?

    matching_categories = matching_categories.reject { |category| gender == "M" && category.gender == "F" }
    p "gender: #{matching_categories.map(&:name).join(', ')}"
    return true if matching_categories.one? && matching_categories.first == race.category
    return false if matching_categories.one? && matching_categories.first != race.category
    return false if matching_categories.none?

    matching_categories = matching_categories.select { |category| ability_begin.in?(category.ability_range) }
    p "ability: #{matching_categories.map(&:name).join(', ')}"
    return true if matching_categories.one? && matching_categories.first == race.category
    return false if matching_categories.one? && matching_categories.first != race.category
    return false if matching_categories.none?

    if junior?
      matching_categories = matching_categories.select { |category| category.junior? }
      p "junior: #{matching_categories.map(&:name).join(', ')}"
      return true if matching_categories.one? && matching_categories.first == race.category
      return false if matching_categories.one? && matching_categories.first != race.category
      return false if matching_categories.none?
    end

    if masters?
      matching_categories = matching_categories.select { |category| category.masters? }
      p "masters?: #{matching_categories.map(&:name).join(', ')}"
      return true if matching_categories.one? && matching_categories.first == race.category
      return false if matching_categories.one? && matching_categories.first != race.category
      return false if matching_categories.none?
    end

    # E.g., if Cat 3 matches Senior Men and Cat 3, use Cat 3
    # Could check size of range and use narrowest if there is a single one more narrow than the others
    # Or maybe the lowest?
    matching_categories = matching_categories.reject { |category| category.all_abilities? }

    p "no wild cards: #{matching_categories.map(&:name).join(', ')}"
    return true if matching_categories.one? && matching_categories.first == race.category
    return false if matching_categories.one? && matching_categories.first != race.category
    return false if matching_categories.none?

    raise "Multiple matches #{matching_categories.map(&:name)} for #{self.name} in #{race.event.categories.map(&:name).join(', ')}"
  end

  def name=(value)
    self[:name] = Category.normalized_name(value)
  end

  def raw_name
    name
  end

  def raw_name=(value)
    self[:name] = value
  end

  # Sr, Mst, Jr, Cat, Beg, Exp
  def short_name
    Category.short_name name
  end

  # Compare by position, then by name
  def <=>(other)
    return -1 if other.nil?
    return super unless other.is_a?(Category)
    return 0 if self[:id] && self[:id] == other[:id]
    diff = (position <=> other.position)
    if diff == 0
      name <=> other.name
    else
      diff
    end
  end

  def to_s
    "#<Category #{id} #{parent_id} #{position} #{name}>"
  end
end
