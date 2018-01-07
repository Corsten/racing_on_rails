# frozen_string_literal: true

# Member velodromes. Only used by ATRA, and not sure they use it any more.
class Velodrome < ActiveRecord::Base
  validates :name, presence: true
  validates :name, uniqueness: true
end
