class UpdateCategoryAbilities < ActiveRecord::Migration
  def change
    ::Category.transaction do
      Category.all.each do |category|
        category.set_abilities_from_name
        category.set_ages_from_name
        category.set_equipment_from_name
        category.set_gender_from_name
        category.set_weight_from_name
        category.save!
      end
    end
  end
end
