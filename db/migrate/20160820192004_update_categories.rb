class UpdateCategories < ActiveRecord::Migration
  def change
    ::Category.transaction do
      Category.all.each do |category|
        category.set_ability_range_from_name
        category.ages = category.ages_from_name(category.name)
        category.set_equipment_from_name
        category.set_gender_from_name
        category.set_weight_from_name

        if category.changed?
          puts "Update #{category.name} #{category.changed.join(', ')}"
        end

        category.save!
      end
    end
  end
end
