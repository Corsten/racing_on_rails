# frozen_string_literal: true

# Old versions of Person. Only goes back since we started using Vestal Versions.
class VersionsController < ApplicationController
  force_https

  before_action :require_current_person
  before_action :assign_person
  before_action :require_same_person_or_administrator_or_editor

  def assign_person
    @person = Person.find(params[:person_id])
    @versions = PaperTrail::Version.where(item_id: @person.id, item_type: "Person")
  end
end
