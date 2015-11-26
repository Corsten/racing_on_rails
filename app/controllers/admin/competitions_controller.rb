module Admin
  class CompetitionsController < Admin::AdminController
    def index
      Competitions::Competition::TYPES.map(&:safe_constantize)
      @competitions = Competitions::Competition.current_year.all
    end

    def edit
      @competition = Event.find(params[:id])
    end

    def update
      @competition = Event.find(params[:id])
      updated = @competition.update(competition_params)
      respond_to do |type|
        type.js do
          if updated
            render plain: "ok"
          else
            render plain: "failed", status: :unprocessable_entity
          end
        end

        type.html do
          if updated
            redirect_to edit_admin_competition_path(@competition)
          else
            render :edit
          end
        end
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
        :enabled,
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
