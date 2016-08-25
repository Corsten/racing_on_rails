require "test_helper"

# :stopdoc:
class CategoryTest < ActiveSupport::TestCase
  test "find all unknowns" do
    unknown = Category.create(name: 'Canine')
    assoc_category = Category.find_or_create_by(name: (RacingAssociation.current.short_name))

    unknowns = Category.find_all_unknowns
    assert_not_nil(unknowns, 'Orphans should not be nil')
    assert(unknowns.include?(unknown), "Orphans should include 'Canine' category")
    assert(!unknowns.include?(assoc_category), "Orphans should not include '#{RacingAssociation.current.short_name}' category")
  end

  # Relies on ActiveRecord ==
  test "sort" do
    [ FactoryGirl.build(:category, id: 2), FactoryGirl.build(:category, id: 1), FactoryGirl.build(:category)].sort
  end

  test "equal" do
    senior_men = FactoryGirl.build(:category, name: "Senior Men", id: 1)
    senior_men_2 = FactoryGirl.build(:category, name: "Senior Men", id: 1)
    assert_equal(senior_men, senior_men_2, 'Senior Men instances')
    assert_equal(senior_men_2, senior_men, 'Senior Men instances')

    senior_men_2.name = ''
    assert_equal(senior_men, senior_men_2, 'Senior Men instances with different names')
    assert_equal(senior_men_2, senior_men, 'Senior Men instances with different names')
  end

  test "no circular parents" do
    category = FactoryGirl.build(:category, name: "Senior Men", id: 1)
    category.parent = category
    assert !category.valid?
  end

  test "no circular parents <<" do
    category = FactoryGirl.build(:category, name: "Senior Men", id: 1)
    category.children << category
    assert !category.valid?
  end

  test "ages default" do
    cat = FactoryGirl.build(:category)
    assert_equal(0, cat.ages_begin, 'ages_begin')
    assert_equal(999, cat.ages_end, 'ages_end is 999')
    assert_equal(0..999, cat.ages, 'Default age range is 0 to 999')
    assert_equal(999, ::Categories::MAXIMUM, '::Categories::MAXIMUM')
  end

  test "to friendly param" do
    assert_equal('', Category.new.to_friendly_param, 'nil friendly_param')
    assert_equal('senior_men', FactoryGirl.build(:category, name: "Senior Men").to_friendly_param, 'senior_men friendly_param')
    assert_equal('pro_expert_women', FactoryGirl.build(:category, name: "Pro, Expert Women").to_friendly_param, 'pro_expert_women friendly_param')
    assert_equal('category_4_5_men', FactoryGirl.build(:category, name: "Category 4/5 Men").to_friendly_param, 'men_4 param')
    assert_equal('singlespeed_fixed', FactoryGirl.build(:category, name: "Singlespeed/Fixed").to_friendly_param, 'single_speed_fixed friendly_param')
    assert_equal('masters_35_plus', FactoryGirl.build(:category, name: "Masters 35+").to_friendly_param, 'masters_35_plus friendly_param')
    assert_equal('pro_semi_pro_men', FactoryGirl.build(:category, name: "Pro, Semi-Pro Men").to_friendly_param, 'pro_semi_pro_men friendly_param')
    assert_equal('category_3_200m_tt', FactoryGirl.build(:category, name: 'Category 3 - 200m TT').to_friendly_param, 'Category 3 - 200m TT friendly_param')
    assert_equal('junior_varisty_15_18_beginner', FactoryGirl.build(:category, name: 'Jr Varisty 15 -18 Beginner').to_friendly_param, 'Jr Varisty 15 -18 Beginner friendly_param')
    assert_equal('tandem_mixed_co_ed', FactoryGirl.build(:category, name: 'Tandem - Mixed (Co-Ed)').to_friendly_param, 'Tandem - Mixed (Co-Ed) friendly_param')
    assert_equal('tandem', FactoryGirl.build(:category, name: '(Tandem)').to_friendly_param, '(Tandem) friendly_param')
  end

  test "find by friendly param" do
    category = FactoryGirl.create(:category, name: "Pro, Semi-Pro Men")
    assert_equal category, Category.find_by_friendly_param("pro_semi_pro_men")
  end

  test "ambiguous find by param" do
    senior_men = FactoryGirl.create(:category, name: "Senior Men")
    senior_men_2 = FactoryGirl.create(:category, name: "Senior/Men")
    assert_equal('senior_men', senior_men.friendly_param)
    assert_equal('senior_men', senior_men_2.friendly_param)
    assert_raises(Categories::AmbiguousParamException) { Category.find_by_friendly_param('senior_men') }
  end

  test "add gender from name" do
    category = Category.create!(name: "Masters Men 60+")
    assert_equal "M", category.gender, "Masters Men 60+ gender"

    category = Category.create!(name: "Junior Women")
    assert_equal "F", category.gender, "Junior Women gender"

    category = Category.create!(name: "Category 3")
    assert_equal "M", category.gender, "Category 3 gender"
  end

  test "add ages from name" do
    category = Category.create!(name: "Masters Men 60+")
    assert_equal 60..999, category.ages

    category = Category.create!(name: "Masters Men 3 40+")
    assert_equal 40..999, category.ages
  end

  test "within" do
    senior_men = Category.find_or_create_by_normalized_name("Senior Men")
    cat_1 = Category.find_or_create_by_normalized_name("Category 1")
    cat_1_2 = Category.find_or_create_by_normalized_name("Category 1/2")
    cat_1_2_3 = Category.find_or_create_by_normalized_name("Category 1/2/3")
    pro_1_2 = Category.find_or_create_by_normalized_name("Pro 1/2")
    cat_2 = Category.find_or_create_by_normalized_name("Category 2")
    cat_3 = Category.find_or_create_by_normalized_name("Category 3")
    cat_3_4 = Category.find_or_create_by_normalized_name("Category 3/4")
    cat_4 = Category.find_or_create_by_normalized_name("Category 4")
    cat_4_women = Category.find_or_create_by_normalized_name("Category 4 Women")
    elite_men = Category.find_or_create_by_normalized_name("Elite Men")
    pro_elite_men = Category.find_or_create_by_normalized_name("Pro Elite Men")
    pro_cat_1 = Category.find_or_create_by_normalized_name("Pro/Category 1")
    masters_men = Category.find_or_create_by_normalized_name("Masters Men")
    masters_novice = Category.find_or_create_by_normalized_name("Masters Novice")
    masters_men_4_5 = Category.find_or_create_by_normalized_name("Masters Men 4/5")
    Category.find_or_create_by_normalized_name("Senior Women")
    junior_men = Category.find_or_create_by_normalized_name("Junior Men")
    junior_women = Category.find_or_create_by_normalized_name("Junior Women")
    junior_men_10_14 = Category.find_or_create_by_normalized_name("Junior Men 10-14")
    junior_men_15_plus = Category.find_or_create_by_normalized_name("Junior 15+")
    junior_men_3_4_5 = Category.find_or_create_by_normalized_name("Junior Men 3/4/5")
    singlespeed = Category.find_or_create_by_normalized_name("Singlespeed/Fixed")
    singlespeed_men = Category.find_or_create_by_normalized_name("Singlespeed Men")
    singlespeed_women = Category.find_or_create_by_normalized_name("Singlespeed Women")

    event = FactoryGirl.create(:event)
    cat_1_race = event.races.create!(category: cat_1)
    cat_2_race = event.races.create!(category: cat_2)
    event.races.create!(category: cat_3)
    cat_4_race = event.races.create!(category: cat_4)

    assert_equal_unordered(
    [ cat_1, cat_1_2, cat_1_2_3 ].map(&:name),
      Category.within(cat_1_race).map(&:name)
    )

    assert_equal_unordered(
      [ cat_2 ].map(&:name),
      Category.within(cat_2_race).map(&:name)
    )

    assert_equal_unordered(
      [ cat_4, cat_4_women, masters_men_4_5 ].map(&:name),
      Category.within(cat_4_race).map(&:name)
    )

    event = FactoryGirl.create(:event)
    cat_1_race = event.races.create!(category: cat_1)
    cat_2_race = event.races.create!(category: cat_2)
    event.races.create!(category: cat_3)
    cat_4_race = event.races.create!(category: cat_4)
    cat_4_women_race = event.races.create!(category: cat_4_women)

    assert_equal_unordered(
    [ cat_1, cat_1_2, cat_1_2_3 ].map(&:name),
      Category.within(cat_1_race).map(&:name)
    )

    assert_equal_unordered(
      [ cat_2 ].map(&:name),
      Category.within(cat_2_race).map(&:name)
    )

    assert_equal_unordered(
      [ cat_4, masters_men_4_5 ].map(&:name),
      Category.within(cat_4_race).map(&:name)
    )

    assert_equal_unordered(
      [ cat_4_women ].map(&:name),
      Category.within(cat_4_women_race).map(&:name)
    )

    event = FactoryGirl.create(:event)
    senior_men_race = event.races.create!(category: senior_men)
    cat_3_race = event.races.create!(category: cat_3)
    cat_4_race = event.races.create!(category: cat_4)
    cat_4_women_race = event.races.create!(category: cat_4_women)
    masters_men_race = event.races.create!(category: masters_men)
    masters_men_4_5_race = event.races.create!(category: masters_men_4_5)
    junior_men_race = event.races.create!(category: junior_men)
    junior_women_race = event.races.create!(category: junior_women)

    assert_equal_unordered(
      [ senior_men, cat_1, cat_1_2, cat_1_2_3, pro_1_2, cat_2, pro_cat_1, elite_men, pro_elite_men, singlespeed, singlespeed_men].map(&:name),
      Category.within(senior_men_race).map(&:name)
    )

    assert_equal_unordered(
      [ cat_3, cat_3_4 ].map(&:name),
      Category.within(cat_3_race).map(&:name)
    )

    assert_equal_unordered(
      [ cat_4 ].map(&:name),
      Category.within(cat_4_race).map(&:name)
    )

    assert_equal_unordered(
      [ cat_4_women ].map(&:name),
      Category.within(cat_4_women_race).map(&:name)
    )

    assert_equal_unordered(
      [ masters_men ].map(&:name),
      Category.within(masters_men_race).map(&:name)
    )

    assert_equal_unordered(
      [ masters_men_4_5, masters_novice ].map(&:name),
      Category.within(masters_men_4_5_race).map(&:name)
    )

    assert_equal_unordered(
      [ junior_men, junior_men_10_14, junior_men_15_plus, junior_men_3_4_5 ].map(&:name),
      Category.within(junior_men_race).map(&:name)
    )

    assert_equal_unordered(
      [ junior_women ].map(&:name),
      Category.within(junior_women_race).map(&:name)
    )

    event = FactoryGirl.create(:event)
    singlespeed_race = event.races.create!(category: singlespeed)

    assert_equal_unordered(
      [ singlespeed, singlespeed_men, singlespeed_women ].map(&:name),
      Category.within(singlespeed_race).map(&:name)
    )

    event = FactoryGirl.create(:event)
    singlespeed_men_race = event.races.create!(category: singlespeed_men)
    singlespeed_women_race = event.races.create!(category: singlespeed_women)

    assert_equal_unordered(
      [ singlespeed_men, singlespeed ].map(&:name),
      Category.within(singlespeed_men_race).map(&:name)
    )

    assert_equal_unordered(
      [ singlespeed_women ].map(&:name),
      Category.within(singlespeed_women_race).map(&:name)
    )
  end
end
