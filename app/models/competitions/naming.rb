module Competitions
  module Naming
    extend ActiveSupport::Concern

    def default_name
      model_name.human
    end
  end
end
