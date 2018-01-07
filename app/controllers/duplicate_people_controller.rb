# frozen_string_literal: true

class DuplicatePeopleController < Admin::AdminController
  def index
    @people = DuplicatePerson.all(params[:limit]&.to_i)
  end

  def destroy
    respond_to do |format|
      format.js do
        @name = params[:id]
        Person.where(name: @name).update_all(other_people_with_same_name: true)
      end
    end
  end
end
