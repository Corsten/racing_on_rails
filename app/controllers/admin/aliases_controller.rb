# frozen_string_literal: true

module Admin
  class AliasesController < Admin::AdminController
    def destroy
      @alias = Alias.find(params[:id])
      @alias.destroy
    end
  end
end
