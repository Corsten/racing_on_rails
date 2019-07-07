# frozen_string_literal: true

require_relative "../../../../app/models/categories"
require_relative "../../../../app/models/categories/ability"
require_relative "../../../../app/models/categories/ages"
require_relative "../../../../app/models/categories/equipment"
require_relative "../../../../app/models/categories/gender"
require_relative "../../../../app/models/categories/matching"
require_relative "../../../../app/models/categories/weight"

require_relative "../../test_case"
require_relative "../../../../app/models/calculations"
require_relative "../../../../app/models/calculations/v3"
require_relative "../../../../app/models/calculations/v3/models"
require_relative "../../../../app/models/calculations/v3/models/association"
require_relative "../../../../app/models/calculations/v3/models/calculated_result"
require_relative "../../../../app/models/calculations/v3/models/category"
require_relative "../../../../app/models/calculations/v3/models/category_rule"
require_relative "../../../../app/models/calculations/v3/models/discipline"
require_relative "../../../../app/models/calculations/v3/models/event_category"
require_relative "../../../../app/models/calculations/v3/models/event"
require_relative "../../../../app/models/calculations/v3/models/participant"
require_relative "../../../../app/models/calculations/v3/models/source_result"
require_relative "../../../../app/models/calculations/v3/rules"
require_relative "../../../../app/models/calculations/v3/steps"
require_relative "../../../../app/models/calculations/v3/steps/add_missing_results_penalty"
require_relative "../../../../app/models/calculations/v3/steps/assign_points"
require_relative "../../../../app/models/calculations/v3/steps/place"
require_relative "../../../../app/models/calculations/v3/steps/reject_below_minimum_events"
require_relative "../../../../app/models/calculations/v3/steps/reject_calculated_events"
require_relative "../../../../app/models/calculations/v3/steps/reject_categories"
require_relative "../../../../app/models/calculations/v3/steps/reject_category_worst_results"
require_relative "../../../../app/models/calculations/v3/steps/reject_dnfs"
require_relative "../../../../app/models/calculations/v3/steps/reject_empty_source_results"
require_relative "../../../../app/models/calculations/v3/steps/reject_more_than_results_per_event"
require_relative "../../../../app/models/calculations/v3/steps/reject_more_than_maximum_events"
require_relative "../../../../app/models/calculations/v3/steps/reject_no_participant"
require_relative "../../../../app/models/calculations/v3/steps/reject_weekday_events"
require_relative "../../../../app/models/calculations/v3/steps/select_in_discipline"
require_relative "../../../../app/models/calculations/v3/steps/select_members"
require_relative "../../../../app/models/calculations/v3/steps/select_association_sanctioned"
require_relative "../../../../app/models/calculations/v3/steps/sum_points"
require_relative "../../../../app/models/calculations/v3/calculators"
require_relative "../../../../app/models/calculations/v3/calculators/categories"
require_relative "../../../../app/models/calculations/v3/calculator"
