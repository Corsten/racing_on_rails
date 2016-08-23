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
    where(
      ability_begin: category.ability_begin,
      ability_end: category.ability_end,
      ages_begin: category.ages_begin,
      ages_end: category.ages_end,
      equipment: category.equipment,
      gender: category.gender,
      weight: category.weight
    )
  }

  scope :within, lambda { |race|
    # TODO match by ages for masters
    # TODO all_ages? all_juniors?
    # TODO Need to handle these as overlapping ranges in different tracks: junior, masters, equipment

    # ability category ranges
    # Senior  0..999 0..2
    # Cat 3   3..3   3..3
    # Cat 4   4..4   4..4
    # Cat 5   5..5   5..5

    # if any age group categories, then apply age range
    # Junior  0..18
    # Senior  19..29
    # Masters 30..999

    # If multiple genders, then apply gender
    # If multiple equipment, then apply equipment
    # If weight weights, then apply weights

    # Or: apply filters, "most restrictive" first?

    # OR: group all categories by their non-default values
    # Road BAR
    # gender: senior men, senior women
    # gender, ability: cat 3 men, cat 4 men, cat 5 men, cat 3 women, cat 4 women, cat 5 men
    # gender, age: junior men, junior women, masters men, masters women
    # gender, age, ability: masters men 4/5
    # equipment: singlespeed
    # weight: clydesdale

    # short track
    # gender, age, ability: Category 1 Men 19-34, Category 3 Men 15-18, Category 1 Men 35-44,
    #    Category 3 Men 19-44, Category 1 Men 45+,Category 3 Men 45+, Category 2 Men 35-44,
    #    Category 3 Women 10-14, Category 2 Men 45-54, Category 3 Women 15-18,
    #    Category 2 Men 55+, Category 3 Women 19+, Category 2 Men U35,
    #    Category 2 Women 35-44, Category 2 Women 45+, Elite/Category 1 Women,
    #    Category 2 Women U35, Category 3 Men 10-14
    # gender, ability: Elite Men
    # weight: Clydesdale
    # equiment, gender: Singlespeed Men, Singlespeed Women

    ability_begin = race.category.ability_begin

    event_abilities = race.event.categories.map(&:ability_begin).uniq.sort
    if race.category.junior?
      event_abilities = race.event.categories.select(&:junior?).map(&:ability_begin).uniq.sort
    elsif race.category.masters?
      event_abilities = race.event.categories.select(&:masters?).map(&:ability_begin).uniq.sort
    elsif race.category.equipment
      event_abilities = race.event.categories.select(&:equipment).map(&:ability_begin).uniq.sort
    end

    if ability_begin == 1 && event_abilities.min == 1
      ability_begin = 0
    end

    index = event_abilities.find_index(race.category.ability_begin)
    next_ability = event_abilities[index + 1]
    ability_end = next_ability || race.category.ability_end
    if ability_end > 0 && ability_end > ability_begin && ability_end < ::Categories::MAXIMUM
      ability_end = ability_end - 1
    end

    query = where("ability_begin >= ? and ability_begin <= ?", ability_begin, ability_end)

    if race.category.equipment && race.event.categories.one? { |c| c.equipment == race.category.equipment }
      query = query.where(
        equipment: race.category.equipment,
        weight: race.category.weight
      )
    else
      query = query.where(
        equipment: race.category.equipment,
        gender: race.category.gender,
        weight: race.category.weight
      )
    end

    if race.category.junior? || race.category.masters?
      query = query.where("ages_begin >= ?", race.category.ages_begin).where("ages_end <= ?", race.category.ages_end)
    elsif race.category.age_group?
      query = query.where("ages_begin = ?", race.category.ages_begin).where("ages_end = ?", race.category.ages_end)
    else
      query = query.where("ages_begin = 0 or ages_begin = ? or (ages_begin > 18 and ages_begin < 30)", ::Categories::MAXIMUM)
    end

    query
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
