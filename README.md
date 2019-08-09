# Fluent::Plugin::PortToService
[![Build Status](https://travis-ci.org/cpedro/fluent-plugin-port_to_service.svg?branch=master)](https://travis-ci.org/cpedro/fluent-plugin-port_to_service)
[![Gem Version](https://badge.fury.io/rb/fluent-plugin-port_to_service.svg)](https://badge.fury.io/rb/fluent-plugin-port_to_service)

## Overview

[Fluentd](http://fluentd.org/) filter plugin to map TCP/UDP ports to service
names. Values are stored in a [SQLite](https://sqlite.org/index.html) database
for simplicity.

## Requirements
| fluent-plugin-port_to_service | fluentd    | ruby   | sqlite3  |
| ----------------------------- | ---------- | ------ | -------- |
| > 0.0.9                       | >= v0.14.0 | >= 2.1 | >= 1.3.7 |

## Dependency

Before use, install dependant libraries, namely sqlite3.

```bash
# for RHEL/CentOS
$ sudo yum groupinstall "Development Tools"
$ sudo yum install sqlite sqlite-devel

# for Ubuntu/Debian
$ sudo apt-get install build-essential
$ sudo apt-get install sqlite3 libsqlite3-dev

# for MacOS
$ brew install sqlite3
```

## Installation

```bash
# for fluentd
$ gem install fluent-plugin-port_to_service

# for td-agent
$ sudo fluent-gem install fluent-plugin-port_to_service

# for td-agent2
$ sudo td-agent-gem install fluent-plugin-port_to_service
```

After installation, you can use the built-in executable to create a database
based on the `/etc/services` file on host.  You have to give the script one
parameter, where you want the database to be created.

```bash
$ fluent-plugin-port_to_service_build_db /etc/td-agent/plugin/port_to_service.db
```

## Configuration

```conf
<filter **>
  @type port_to_service

  # Required parameters
  path          /etc/td-agent/plugin/port_to_service.db

  # Optional parameters
  port_key      port
  protocol_key  protocol
  service_key   service
</filter>
```

If the following record is passed in:
```json
{"protocol": "tcp", "port": "22", "foo": "bar"}
```

The filtered record will be:
```json
{"protocol": "tcp", "port": "22", "service": "ssh", "foo": "bar"}
```

## SQLite3 Database Setup

The plugin requires a SQLite database to be built. The database just needs a
single table called `services` with 3 **mandatory** columns:
* `port` - Integer
* `protocol` - Text
* `service` - Text

You can also add a primary key, `id`, but it's only required for posterity.

Example:
```bash
$ sqlite3 /etc/td-agent/plugin/port_to_service.db
sqlite> CREATE TABLE services(id INTEGER PRIMARY KEY, port INTEGER, protocol TEXT, service TEXT);
sqlite> INSERT INTO services(port, protocol, service) VALUES (22, 'tcp', 'ssh');
...
```

Alternatively, there is a script provided that parses `/etc/services` and
creates the required database with the services.  You have to specify one
command line parameter, and that is the file path you wish to install the
database to.

```bash
$ fluent-plugin-port_to_service_build_db /etc/td-agent/plugin/port_to_service.db
```

## Copyright
​
Copyright(c) 2019- [Chris Pedro](https://chris.thepedros.com/)

## License

[The Unlicense](https://unlicense.org/)
