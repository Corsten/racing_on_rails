# frozen_string_literal: true

module Versions
  extend ActiveSupport::Concern

  included do
    has_paper_trail class_name: "PaperTrailVersion",
                    versions: :paper_trail_versions,
                    version:  :paper_trail_version
  end
end
