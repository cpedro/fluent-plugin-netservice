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

  BASIC_CONFIG = %[
    @type         port_to_service

    # Required parameters
    path          test/test_port_to_service.db

    # Optional parameters
    port_key      port
    protocol_key  protocol
    service_key   service
  ]

  test "single_tcp_record" do
    filter_and_test(BASIC_CONFIG,
      [{"protocol"=> "tcp", "port"=> "22", "foo"=> "bar"}],
      [{"protocol"=> "tcp", "port"=> "22", "service"=> "ssh", "foo"=> "bar"}])
  end

  test "single_udp_record" do
    filter_and_test(BASIC_CONFIG,
      [{"protocol"=> "udp", "port"=> "123", "foo"=> "bar"}],
      [{"protocol"=> "udp", "port"=> "123", "service"=> "ntp", "foo"=> "bar"}])
  end

  test "mutliple_records" do
    filter_and_test(BASIC_CONFIG,
      [
        {"protocol"=> "tcp", "port"=> "22", "foo"=> "bar"},
        {"protocol"=> "udp", "port"=> "53"}
      ],
      [
        {"protocol"=> "tcp", "port"=> "22", "service"=> "ssh", "foo"=> "bar"},
        {"protocol"=> "udp", "port"=> "53", "service"=> "domain"}
      ])
  end

  test "multiple_records_same_port" do
    filter_and_test(BASIC_CONFIG,
      [
        {"protocol"=> "tcp", "port"=> "161"},
        {"protocol"=> "udp", "port"=> "161"}
      ],
      [
        {"protocol"=> "tcp", "port"=> "161", "service"=> "snmp"},
        {"protocol"=> "udp", "port"=> "161", "service"=> "snmp"}
      ])
  end

  test "multiple_records_same_protocol" do
    filter_and_test(BASIC_CONFIG,
      [
        {"protocol"=> "tcp", "port"=> "80"},
        {"protocol"=> "tcp", "port"=> "123"}
      ],
      [
        {"protocol"=> "tcp", "port"=> "80", "service"=> "http"},
        {"protocol"=> "tcp", "port"=> "123", "service"=> "ntp"}
      ])
  end

  test "records_with_missing_fields" do
    filter_and_test(BASIC_CONFIG,
      [
        {"protocol"=> "tcp"},
        {"port"=> "80"},
        {"foo"=> "bar"}
      ],
      [
        {"protocol"=> "tcp"},
        {"port"=> "80"},
        {"foo"=> "bar"}
      ])
  end

  test "not_found" do
    filter_and_test(BASIC_CONFIG,
      [
        {"protocol"=> "tcp", "port"=> "1024"},
        {"protocol"=> "udp", "port"=> "22"},
        {"protocol"=> "icmp", "port"=> "1024"}
      ],
      [
        {"protocol"=> "tcp", "port"=> "1024"},
        {"protocol"=> "udp", "port"=> "22"},
        {"protocol"=> "icmp", "port"=> "1024"}
      ])
  end

  test "with_defaults" do
    filter_and_test(
      %[
        @type port_to_service
        path  test/test_port_to_service.db
      ],
      [
        {"protocol"=> "tcp", "port"=> "22"},
        {"protocol"=> "udp", "port"=> "53"},
        {"protocol"=> "udp", "port"=> "161"},
        {"protocol"=> "tcp", "port"=> "161"},
        {"protocol"=> "tcp"},
        {"port"=> "161"},
        {"foo"=> "bar"}
      ],
      [
        {"protocol"=> "tcp", "port"=> "22", "service"=> "ssh"},
        {"protocol"=> "udp", "port"=> "53", "service"=> "domain"},
        {"protocol"=> "udp", "port"=> "161", "service"=> "snmp"},
        {"protocol"=> "tcp", "port"=> "161", "service"=> "snmp"},
        {"protocol"=> "tcp"},
        {"port"=> "161"},
        {"foo"=> "bar"}
      ])
  end

  test "with_diff_optional" do
    filter_and_test(
      %[
        @type         port_to_service
        path          test/test_port_to_service.db
        port_key      a_port
        protocol_key  a_protocol
        service_key   a_service
      ],
      [
        {"a_protocol"=> "tcp", "a_port"=> "22"},
        {"a_protocol"=> "tcp", "port"=> "22"},
        {"protocol"=> "tcp", "a_port"=> "22"},
        {"protocol"=> "tcp", "port"=> "22"}
      ],
      [
        {"a_protocol"=> "tcp", "a_port"=> "22", "a_service"=> "ssh"},
        {"a_protocol"=> "tcp", "port"=> "22"},
        {"protocol"=> "tcp", "a_port"=> "22"},
        {"protocol"=> "tcp", "port"=> "22"}
      ])
  end

  private

  def create_driver(config)
    Fluent::Test::Driver::Filter.new(
      Fluent::Plugin::PortToServiceFilter).configure(config)
  end

  def filter_and_test(config, original, expected)
    d = create_driver(config)
    yield d if block_given?
    d.run(default_tag: @tag) {
      original.each {|message|
        d.feed(@time, message)
      }
    }
    filtered = d.filtered_records
    assert_equal expected, filtered
  end
end
