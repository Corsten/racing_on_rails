# frozen_string_literal: true

module BarHelper
  BAR_POINTS_AND_LABELS = [["None", 0], ["Normal", 1], ["Double", 2], ["Triple", 3]].freeze unless defined?(BAR_POINTS_AND_LABELS)

  def bar_points_and_labels
    BAR_POINTS_AND_LABELS
  end
end
