# frozen_string_literal: true

require "active_support/core_ext/object/inclusion"

module Categories
  module Matching
    extend ActiveSupport::Concern

    # Find best matching competition race for category. Iterate through traits (weight, equipment, ages, gender, abilities) until there is a
    # single match (or none).
    def best_match_in_event(event)
      # TODO logger.debug "Category#best_match_in #{name} in #{event.name}"
      best_match_in event_categories
    end

    # Find best matching competition race for category. Iterate through traits (weight, equipment, ages, gender, abilities) until there is a
    # single match (or none).
    def best_match_in(event_categories)
      # TODO logger.debug "Category#best_match_in #{name}: #{event_categories.map(&:name).join(', ')}"

      candidate_categories = event_categories.dup

      equivalent_match = candidate_categories.detect { |category| equivalent?(category) }
      # TODO logger.debug "equivalent: #{equivalent_match&.name}"
      return equivalent_match if equivalent_match

      candidate_categories = candidate_categories.select { |category| weight == category.weight }
      # TODO logger.debug "weight: #{candidate_categories.map(&:name).join(', ')}"

      candidate_categories = candidate_categories.select { |category| equipment == category.equipment }
      # TODO logger.debug "equipment: #{candidate_categories.map(&:name).join(', ')}"

      candidate_categories = candidate_categories.select { |category| ages_begin.in?(category.ages) }
      # TODO logger.debug "ages: #{candidate_categories.map(&:name).join(', ')}"

      candidate_categories = candidate_categories.reject { |category| gender == "M" && category.gender == "F" }
      # TODO logger.debug "gender: #{candidate_categories.map(&:name).join(', ')}"

      candidate_categories = candidate_categories.select { |category| ability_begin.in?(category.abilities) }
      # TODO logger.debug "ability: #{candidate_categories.map(&:name).join(', ')}"
      return candidate_categories.first if candidate_categories.one?
      return nil if candidate_categories.empty?

      if junior?
        junior_categories = candidate_categories.select(&:junior?)
        # TODO logger.debug "junior: #{junior_categories.map(&:name).join(', ')}"
        return junior_categories.first if junior_categories.one?

        candidate_categories = junior_categories if junior_categories.present?
      end

      if masters?
        masters_categories = candidate_categories.select(&:masters?)
        # TODO logger.debug "masters?: #{masters_categories.map(&:name).join(', ')}"
        return masters_categories.first if masters_categories.one?

        candidate_categories = masters_categories if masters_categories.present?
      end

      # E.g., if Cat 3 matches Senior Men and Cat 3, use Cat 3
      # Could check size of range and use narrowest if there is a single one more narrow than the others
      candidate_categories = candidate_categories.reject(&:all_abilities?)
      # TODO logger.debug "reject wildcards: #{candidate_categories.map(&:name).join(', ')}"
      return candidate_categories.first if candidate_categories.one?
      return nil if candidate_categories.empty?

      # "Highest" is lowest ability number
      # Choose exact ability category begin if women
      # Common edge case where the two highest categories are Pro/1/2 and Women 1/2
      if candidate_categories.one? { |category| category.ability_begin == ability_begin && category.women? && women? }
        ability_category = candidate_categories.detect { |category| category.ability_begin == ability_begin && category.women? && women? }
        # TODO logger.debug "ability begin: #{ability_category.name}"
        return ability_category
      end

      # Choose highest ability category
      highest_ability = candidate_categories.map(&:ability_begin).min
      if candidate_categories.one? { |category| category.ability_begin == highest_ability }
        highest_ability_category = candidate_categories.detect { |category| category.ability_begin == highest_ability }
        # TODO logger.debug "highest ability: #{highest_ability_category.name}"
        return highest_ability_category
      end

      candidate_categories = candidate_categories.reject { |category| gender == "F" && category.gender == "M" }
      # TODO logger.debug "exact gender: #{candidate_categories.map(&:name).join(', ')}"
      return candidate_categories.first if candidate_categories.one?
      return nil if candidate_categories.empty?

      # TODO logger.debug "no wild cards: #{candidate_categories.map(&:name).join(', ')}"
      return candidate_categories.first if candidate_categories.one?
      return nil if candidate_categories.empty?

      raise "Multiple matches #{candidate_categories.map(&:name)} for #{name} in #{event_categories.map(&:name).join(', ')}"
    end

    def equivalent?(other)
      return false unless other

      abilities == other.abilities &&
        ages == other.ages &&
        equipment == other.equipment &&
        gender == other.gender &&
        weight == other.weight
    end

    def in?(other)
      return false unless other

      abilities.in?(other.abilities) &&
        ages.in?(other.ages) &&
        equipment == other.equipment &&
        (other.gender == "M" || gender == "F") &&
        weight == other.weight
    end
  end
end
