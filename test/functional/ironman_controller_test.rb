require "test_helper"

class IronmanControllerTest < ActionController::TestCase
  def test_index
    big_team = Team.create(:name => "T" * 60)
    weaver = racers(:weaver)
    weaver.team = big_team
    events(:banana_belt_1).standings.first.races.first.results.create(:racer => weaver, :team => big_team)
    weaver.first_name = "f" * 60
    weaver.last_name = "T" * 60

    Ironman.recalculate(2004)
    Ironman.recalculate

    opts = {:controller => "ironman", :action => "index", :year => "2004"}
    assert_routing("/ironman/2004", opts)
    opts = {:controller => "ironman", :action => "index"}
    assert_routing("/ironman", opts)

    get(:index, :year => "2004")
    assert_response(:success)
    assert_template("ironman/index")
    assert_not_nil(assigns["ironman"], "Should assign ironman")
    assert_not_nil(assigns["year"], "Should assign year")
    assert_not_nil(assigns["years"], "Should assign years")

    get(:index)
    assert_response(:success)
    assert_template("ironman/index")
    assert_not_nil(assigns["ironman"], "Should assign ironman")
    assert_not_nil(assigns["year"], "Should assign year")
    assert_not_nil(assigns["years"], "Should assign years")
  end
end
