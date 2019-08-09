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

Use RubyGems to install sqlite3 first, then copy plugin over.
install with `gem` or td-agent provided command as:

```bash
# for fluentd
$ gem install sqlite3

# for td-agent
$ sudo fluent-gem install sqlite3

# for td-agent2
$ sudo td-agent-gem install sqlite3
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
creates the required database with the services.  This should be run from the
fluent-plugin-port_to_service directory and creates the the SQLite database
at `lib/fluent/plugin/port_to_service.db`.  The SQL to create the database will
be in `lib/fluent/plugin/port_to_service.sql`.

```bash
$ pwd
/path/to/fluent-plugin-port_to_service
$ script/db-build.sh
```

## Copyright
​
Copyright(c) 2019- [Chris Pedro](https://chris.thepedros.com/)

## License

[The Unlicense](https://unlicense.org/)
