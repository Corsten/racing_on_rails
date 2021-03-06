# frozen_string_literal: true

class Region < ApplicationRecord
  include Regions::FriendlyParam

  before_save :set_friendly_param

  def set_friendly_param
    self.friendly_param = to_param
  end
end
