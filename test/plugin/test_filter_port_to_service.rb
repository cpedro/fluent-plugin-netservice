require "helper"
require "fluent/plugin/filter_port_to_service.rb"

class PortToServiceFilterTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  test "failure" do
    flunk
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Filter.new(Fluent::Plugin::PortToServiceFilter).configure(conf)
  end
end
