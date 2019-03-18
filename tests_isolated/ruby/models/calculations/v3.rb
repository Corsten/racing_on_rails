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
require_relative "../../../../app/models/calculations/v3/calculator"
require_relative "../../../../app/models/calculations/v3/models"
require_relative "../../../../app/models/calculations/v3/models/calculated_result"
require_relative "../../../../app/models/calculations/v3/models/category"
require_relative "../../../../app/models/calculations/v3/models/event_category"
require_relative "../../../../app/models/calculations/v3/models/event"
require_relative "../../../../app/models/calculations/v3/models/participant"
require_relative "../../../../app/models/calculations/v3/models/source_result"
require_relative "../../../../app/models/calculations/v3/rules"
require_relative "../../../../app/models/calculations/v3/steps"
require_relative "../../../../app/models/calculations/v3/steps/assign_points"
require_relative "../../../../app/models/calculations/v3/steps/map_source_results_to_results"
require_relative "../../../../app/models/calculations/v3/steps/place"
require_relative "../../../../app/models/calculations/v3/steps/reject_no_participant"
require_relative "../../../../app/models/calculations/v3/steps/reject_worst_results"
require_relative "../../../../app/models/calculations/v3/steps/sum_points"
