# frozen_string_literal: true

module RacingOnRails::PaperTrail::Versions
  extend ActiveSupport::Concern

  included do
    belongs_to :created_by_paper_trail, polymorphic: true
    belongs_to :updated_by_paper_trail, polymorphic: true

    has_paper_trail class_name: "RacingOnRails::PaperTrail::Version",
                    versions: :paper_trail_versions,
                    version:  :paper_trail_version

    before_save :set_created_by
    before_save :set_created_by_and_updated_by_paper_trail
  end

  def set_created_by
    return if created_by
    self.created_by_paper_trail = PaperTrail.whodunnit
  end

  def set_created_by_and_updated_by_paper_trail
    self.created_by_paper_trail ||= (created_by || updated_by_record || ::Person.current)
    self.updated_by_paper_trail = updated_by_record || created_by_paper_trail
    true
  end
end
