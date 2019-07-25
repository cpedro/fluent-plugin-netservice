require "helper"
require "fluent/plugin/filter_port_to_service.rb"
require 'fluent/test/driver/filter'

=begin
Unit tests require test database.  It can be created by running the below
command with included SQL file:

$ sqlite3 test/test_port_to_service.db < test/test_port_to_service.sql

OR build by just running:

$ cat <<EOF | sqlite3 test/test_port_to_service.db
CREATE TABLE services(
  id INTEGER PRIMARY KEY,
  port INTEGER,
  protocol TEXT,
  service TEXT);
INSERT INTO services(port, protocol, service) VALUES (22, 'tcp', 'ssh');
INSERT INTO services(port, protocol, service) VALUES (53, 'udp', 'domain');
INSERT INTO services(port, protocol, service) VALUES (80, 'tcp', 'http');
INSERT INTO services(port, protocol, service) VALUES (123, 'udp', 'ntp');
INSERT INTO services(port, protocol, service) VALUES (123, 'tcp', 'ntp');
INSERT INTO services(port, protocol, service) VALUES (161, "udp", "snmp");
INSERT INTO services(port, protocol, service) VALUES (161, "tcp", "snmp");
EOF

$ sqlite3 test/test_port_to_service.db < test/test_port_to_service.sql
=end

class PortToServiceFilterTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
    @tag = "test.tag"
    @time = Fluent::Engine.now
  end

  CONFIG = %[
    @type port_to_service

    # Required parameters
    path          test/test_port_to_service.db

    # Optional parameters
    port_key      port
    protocol_key  protocol
    service_key   service
  ]

  test "single_tcp_record" do
    messages = [
      {"protocol" => "tcp", "port" => "22"}
    ]
    expected = [
      {"protocol" => "tcp", "port" => "22", "service" => "ssh"}
    ]
    filtered = filter(CONFIG, messages)
    assert_equal expected, filtered
  end

  test "single_udp_record" do
    messages = [
      {"protocol" => "udp", "port" => "53"}
    ]
    expected = [
      {"protocol" => "udp", "port" => "53", "service" => "domain"}
    ]
    filtered = filter(CONFIG, messages)
    assert_equal expected, filtered
  end

  test "mutliple_records" do
    messages = [
      {"protocol" => "tcp", "port" => "22"},
      {"protocol" => "udp", "port" => "53"}
    ]
    expected = [
      {"protocol" => "tcp", "port" => "22", "service" => "ssh"},
      {"protocol" => "udp", "port" => "53", "service" => "domain"}
    ]
    filtered = filter(CONFIG, messages)
    assert_equal expected, filtered
  end

  test "multiple_records_same_port" do
    messages = [
      {"protocol" => "tcp", "port" => "123"},
      {"protocol" => "udp", "port" => "123"}
    ]
    expected = [
      {"protocol" => "tcp", "port" => "123", "service" => "ntp"},
      {"protocol" => "udp", "port" => "123", "service" => "ntp"}
    ]
    filtered = filter(CONFIG, messages)
    assert_equal expected, filtered
  end

  test "multiple_records_same_protocol" do
    messages = [
      {"protocol" => "tcp", "port" => "80"},
      {"protocol" => "tcp", "port" => "123"}
    ]
    expected = [
      {"protocol" => "tcp", "port" => "80", "service" => "http"},
      {"protocol" => "tcp", "port" => "123", "service" => "ntp"}
    ]
    filtered = filter(CONFIG, messages)
    assert_equal expected, filtered
  end

  test "records_with_missing_fields" do
    messages = [
      {"protocol" => "tcp"},
      {"port" => "80"},
      {"foo" => "bar"}
    ]
    expected = [
      {"protocol" => "tcp"},
      {"port" => "80"},
      {"foo" => "bar"}
    ]
    filtered = filter(CONFIG, messages)
    assert_equal expected, filtered
  end

  test "full_test" do
    messages = [
      {"protocol" => "tcp", "port" => "22"},
      {"protocol" => "udp", "port" => "53"},
      {"protocol" => "tcp", "port" => "80"},
      {"protocol" => "udp", "port" => "123"},
      {"protocol" => "tcp", "port" => "123"},
      {"protocol" => "udp", "port" => "161"},
      {"protocol" => "tcp", "port" => "161", "foo" => "bar"},
      {"protocol" => "tcp"},
      {"port" => "161"},
      {"foo" => "bar"}
    ]
    expected = [
      {"protocol" => "tcp", "port" => "22", "service" => "ssh"},
      {"protocol" => "udp", "port" => "53", "service" => "domain"},
      {"protocol" => "tcp", "port" => "80", "service" => "http"},
      {"protocol" => "udp", "port" => "123", "service" => "ntp"},
      {"protocol" => "tcp", "port" => "123", "service" => "ntp"},
      {"protocol" => "udp", "port" => "161", "service" => "snmp"},
      {"protocol" => "tcp", "port" => "161", "service" => "snmp", "foo" => "bar"},
      {"protocol" => "tcp"},
      {"port" => "161"},
      {"foo" => "bar"}
    ]
    filtered = filter(CONFIG, messages)
    assert_equal expected, filtered
  end

  private

  def filter(config, messages)
    d = create_driver(config)
    yield d if block_given?
    d.run(default_tag: @tag) {
      messages.each {|message|
        d.feed(@time, message)
      }
    }
    d.filtered_records
  end

  def create_driver(conf)
    Fluent::Test::Driver::Filter.new(Fluent::Plugin::PortToServiceFilter).configure(conf)
  end
end
