# frozen_string_literal: true

class ChangePostsPositionDefault < ActiveRecord::Migration
  def up
    change_column :posts, :position, :integer, default: nil, null: true
  end

  def down
    change_column :posts, :position, :integer, default: 0, null: false
  end
end
