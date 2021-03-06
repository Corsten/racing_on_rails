# frozen_string_literal: true

module Results
  module Renderers
    class ScoreEventFullNameRenderer < Results::Renderers::DefaultResultRenderer
      def self.render(column, row)
        return nil unless row.source.respond_to?(:competition_result?)

        if row.source.competition_result?
          "<a href=\"/events/#{row.source.event_id}/people/#{row.source.person_id}/results#race_#{row.source.race_id}\">#{row[column.key]}</a>"
        else
          "<a href=\"/events/#{row.source.event_id}/results#race_#{row.source.race_id}\">#{row[column.key]}</a>"
        end
      end
    end
  end
end
