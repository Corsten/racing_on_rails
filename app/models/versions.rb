# frozen_string_literal: true

module Versions
  extend ActiveSupport::Concern

  included do
    belongs_to :created_by, class_name: "Person", inverse_of: :creations

    puts ">>> has_paper_trail"
    has_paper_trail class_name: "PaperTrailVersion",
                    versions: :paper_trail_versions,
                    version:  :paper_trail_version

    before_save :set_created_by
  end

  def set_created_by
    return if created_by
    self.created_by = PaperTrail.whodunnit
  end
end
