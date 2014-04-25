require "test_helper"

module Categories
  # :stopdoc:
  class CleanupTest < ActiveSupport::TestCase
    test "cleanup!" do
      Category.expects(:destroy_unused!)
      Category.expects(:cleanup_names!)
      Category.cleanup!
    end

    test "cleanup_names!" do
      senior_men = FactoryGirl.create(:category, name: "Senior Men")
      Category.connection.execute "insert into categories (name, friendly_param) values (' Senior Men ', 'sr2')"
      Category.connection.execute "insert into categories (name, friendly_param) values (' Men A', 'men_a')"

      Category.cleanup_names!

      assert_equal 2, Category.count, "Should remove duplicate category"
      assert Category.where(id: senior_men.id).exists?, "Should keep 'good' category"
      assert Category.where(name: "Men A").exists?, "Should fix category name"
    end

    test "in_use?" do
      senior_men = FactoryGirl.create(:category, name: "Senior Men")
      men_c = FactoryGirl.create(:category, name: "Men C", parent: senior_men)
      discipline_bar_category = FactoryGirl.create(:category)
      Discipline.create!(name: "Road", bar: true).bar_categories << discipline_bar_category
      race_category = FactoryGirl.create(:race).category
      cat4_womens_race_series_category = RacingAssociation.current.cat4_womens_race_series_category
      result_category = FactoryGirl.create(:category)
      FactoryGirl.create(:result, category: result_category)

      assert senior_men.in_use?, "Category with children is in use"
      assert !men_c.in_use?, "unused category should be in use"
      assert discipline_bar_category.in_use?, "Discipline BAR category should be in use"
      assert race_category.in_use?, "race category"
      assert cat4_womens_race_series_category.in_use?, "RacingAssociation#cat4_womens_race_series_category should be in use"
      assert result_category.in_use?, "Result category should be in use"
    end
  end
end