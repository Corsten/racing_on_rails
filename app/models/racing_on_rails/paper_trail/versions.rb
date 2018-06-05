# frozen_string_literal: true

module RacingOnRails::PaperTrail::Versions
  extend ActiveSupport::Concern

  included do
    has_paper_trail class_name: "RacingOnRails::PaperTrail::Version",
                    ignore: %i[
                               created_by_paper_trail_id
                               created_by_paper_trail_name
                               created_by_paper_trail_type
                               current_login_at
                               current_login_ip
                               last_login_at
                               last_login_ip
                               login_count
                               password_salt
                               perishable_token
                               persistence_token
                               single_access_token
                               updated_by_paper_trail_id
                               updated_by_paper_trail_name
                               updated_by_paper_trail_type
                             ],
                    versions: :paper_trail_versions,
                    version:  :paper_trail_version

    before_save :set_created_by_paper_trail
    before_save :set_updated_by_paper_trail
  end

  def set_created_by_paper_trail
    return true if created_by_paper_trail_name

    if updater
      self.created_by_paper_trail_name = updater.name
      self.created_by_paper_trail_type = updater.class.name
    else
      self.created_by_paper_trail_name = ::Person.current&.name
      self.created_by_paper_trail_type = ::Person.current&.class&.name
    end

    true
  end

  def set_updated_by_paper_trail
    if updater
      self.updated_by_paper_trail_name = updater.name
      self.updated_by_paper_trail_type = updater.class.name
    else
      self.updated_by_paper_trail_name = ::Person.current&.name
      self.updated_by_paper_trail_type = ::Person.current&.class&.name
    end

    true
  end
end
