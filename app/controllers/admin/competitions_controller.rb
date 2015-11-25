module Admin
  class CompetitionsController < Admin::AdminController
    def edit
      @competition = Event.find(params[:id])
    end

    def update
      @competition = Event.find(params[:id])
      if @competition.update(competition_params)
        redirect_to edit_admin_competition_path(@competition)
      else
        render :edit
      end
    end

    private

    def competition_params
      params_without_mobile.require(:competition).permit(
        :break_ties,
        :category_names_string,
        :default_bar_points,
        :default_discipline,
        :dnf_points,
        :double_points_for_last_event,
        :field_size_bonus,
        :maximum_events,
        :maximum_upgrade_points,
        :members_only,
        :minimum_events,
        :missing_result_penalty,
        :most_points_win,
        :parent_event_name,
        :place_bonus_string,
        :place_bonus,
        :point_schedule_from_field_size,
        :point_schedule_string,
        :race_category_names_string,
        :results_per_event,
        :results_per_race,
        :source_event_types_string,
        :source_events,
        :source_result_category_names_string,
        :team,
        :use_source_result_points,
      )
    end
  end
end
