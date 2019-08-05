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

    def initialize
      super
    end

    def configure(conf)
      compat_parameters_convert(conf, :inject)
      super
    end

    def start
      super
      log.info "filter_port_to_service.rb - database path: #{@path}"
      @db = @db = ::SQLite3::Database.new @path
      @db.results_as_hash = true
    end

    def shutdown
      @db.close if @db
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
      # Return if any of the fields are not found.
      return record unless record[@protocol_key] && record[@port_key]

      # Reading in parameters from sources aren't always UTF-8.
      protocol = record[@protocol_key].downcase.encode("UTF-8")
      port = record[@port_key].to_i

      # Return if protocol or port is out of range.
      return record unless PROTOCOLS.include?(protocol) && PORTS.include?(port)

      service = get_service(protocol, port)
      if service
        record[@service_key] = service
      end
      record
    end

    def get_service(protocol, port)
      begin
        log.debug "filter_port_to_service.rb - protocol: #{protocol}
          class: #{protocol.class} encoding: #{protocol.encoding}"
        log.debug "filter_port_to_service.rb - port: #{port}
          class: #{port.class}"

        stmt = @db.prepare SQUERY
        stmt.bind_param 1, protocol
        stmt.bind_param 2, port

        rs = stmt.execute
        if row = rs.next
          service = row["service"]
        end

        log.debug "filter_port_to_service.rb - Service: #{service}"
      rescue ::SQLite3::Exception => e
        log.error "filter_port_to_service.rb - Error: #{e}"
      ensure
        stmt.close if stmt
      end

      service
    end
  end
end

