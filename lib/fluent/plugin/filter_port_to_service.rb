# filter_port_to_service.rb

require "fluent/plugin/filter"
require "sqlite3"

module Fluent::Plugin
  class PortToServiceFilter < Fluent::Plugin::Filter
    Fluent::Plugin.register_filter("port_to_service", self)

    SQUERY = "SELECT service FROM services WHERE protocol = ? and port = ?;"

    PROTOCOLS = ["tcp", "udp"]
    PORTS = (1..65535)

    helpers :compat_parameters, :inject, :record_accessor

    desc "Protocol key"
    config_param :protocol_key, :string, default: "protocol"
    desc "Port number key"
    config_param :port_key, :string, default: "port"
    desc "Key name to use to store service description"
    config_param :service_key, :string, default: "service"
    desc "SQLite3 database path"
    config_param :path, :string
    desc "SQLite3 databse table name"
    config_param :table, :string, default: "services"

    def initialize
      super
    end

    def configure(conf)
      compat_parameters_convert(conf, :inject)
      super
    end

    def start
      super
      @db = @db = ::SQLite3::Database.new @path
      @db.results_as_hash = true
      @stmts = {}
    end

    def shutdown
      @stmts.each {|k,v| v.close}
      @db.close
      super
    end

    def filter(tag, time, record)
      filtered_record = add_service(record)
      if filtered_record
        record = filtered_record
      end

      record = inject_values_to_record(tag, time, record)
      record
    end

    def add_service(record)
      protocol = record[@protocol_key].downcase
      port = record[@port_key].to_i

      return record unless PROTOCOLS.include?(protocol) && PORTS.include?(port)

      service = get_service(protocol, port)
      if service
        record[@service_key] = service
      end
      record
    end

    def get_service(protocol, port)
      @stmts = @db.prepare SQUERY
      @stmts.bind_param 1, protocol
      @stmts.bind_param 2, port

      rs = @stmts.execute
      row = rs.next
      service = row["service"]
      service
    end
  end
end

