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