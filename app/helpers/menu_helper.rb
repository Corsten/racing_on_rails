# frozen_string_literal: true

module MenuHelper
  def build_menu
    article_categories = ArticleCategory.where(parent_id: "0").order("position")
    discipline_names = Discipline.names
    render "shared/menu", article_categories: article_categories, discipline_names: discipline_names
  end
end
