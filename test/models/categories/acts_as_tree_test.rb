# frozen_string_literal: true

require "test_helper"

module Categories
  # :stopdoc:
  class ActsAsTreeTest < ActiveSupport::TestCase
    test "#descendants should not modify association" do
      root = FactoryBot.create(:category)
      node = FactoryBot.create(:category, parent: root)
      leaf = FactoryBot.create(:category, parent: node)

      root.reload.descendants
      node.reload.descendants
      leaf.reload.descendants

      assert_nil root.reload.parent, "root parent"
      assert_equal root, node.reload.parent, "node parent"
      assert_equal node, leaf.reload.parent, "leaf parent"
    end
  end
end
