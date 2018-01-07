# frozen_string_literal: true

class AddCategoriesGender < ActiveRecord::Migration
  def change
    add_column :categories, :gender, :string, default: "M", null: false
  end
end
