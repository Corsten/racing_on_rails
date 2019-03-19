# frozen_string_literal: true

# Person or team that owns a result. Teams can be permanent year-long teams,
# or event-only teams.
module Calculations
  module V3
    module Models
      class Participant
        attr_reader :id

        def initialize(id)
          @id = id
        end
      end
    end
  end
end