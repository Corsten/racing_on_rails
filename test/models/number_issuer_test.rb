# frozen_string_literal: true

require File.expand_path("../../test_helper", __FILE__)

# :stopdoc:
class NumberIssuerTest < ActiveSupport::TestCase
  test "create" do
    NumberIssuer.create(name: "Elkhorn Classic SR")
    assert(!NumberIssuer.new.valid?, "Null name")
    assert(!NumberIssuer.new(name: "").valid?, "Empty name")
  end
end
