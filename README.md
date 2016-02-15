gna-sensu-wrapper Cookbook
===========================

GNA Sensu cookbook installs and configures a Sensu server and clients to
monitor servers' state and collect statistical metrics. This cookbook requires
creation of  2 data bags **sensu** and **sensu_checks** (see description below)

Requirements
------------
- `sensu` -- Sensu cookbook provides all the resources required by
  gna-sensu-wrapper

Attributes
----------

#### gna-sensu-cookbook::default
<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>["sensu"]["use_embedded_ruby"]</tt></td>
    <td>Boolean</td>
    <td>Sensu relies on embedded Ruby</td>
    <td><tt>true</tt></td>
  </tr>
  <tr>
    <td><tt>["sensu"]["version"]</tt></td>
    <td>String</td>
    <td>Version of Sensu to install</td>
    <td><tt>0.16.0-1</tt></td>
  </tr>
  <tr>
    <td><tt>["uchiwa"]["version"]</tt></td>
    <td>String</td>
    <td>Version of Uchiva (Web GUI) to install</td>
    <td><tt>0.7.1-1</tt></td>
  </tr>
  <tr>
    <td><tt>["gna_sensu_wrapper"]["roles"]</tt></td>
    <td>Array</td>
    <td>Sets roles which define which checks and metrics to run</td>
    <td><tt>Empty</tt></td>
  </tr>
</table>

Included plugins
----------------

Sensu plugins either monitor some system parameters and warn about close to
critical and critical conditions for these parameters. For example
`check-disk.rb` plugin monitors percentage of disk space left on each partition
of the servers.

You can find included plugins in [files/default/plugins][1]. A comment on top
of of every plugin file explains it's purpose

Build-in "plugin"
-----------------

Keepalive is an internal Sensu service which gets signals from sensu clients
from all the machines. If server is down or sensu-slient stopped working --
server generates alert message and sends it the alerts to all keepalive
handlers. These handlers are setup differently from checks, and are described
further below.

Included handlers
-----------------

Sensu handlers allow send alerts from Sensu checks and metrics to various
communication channels -- Twitter, Email, Gitter etc. For example
`ponymailer.rb` handler sends alerts by email to subscribed administrators.

You can find included handlers in [files/default/handlers][2]. A comment on top
of of every handler file explains it's purpose

Adding new plugins and handlers
-------------------------------

If you want to check for additional system paramters, collect different metrics
or to send alert to a new service -- you can start by looking at existing
[Sensu community plugins][3]. You can modify scripts to your needs or write
your own.


Usage
-----

To configure your Sensu installation decide which machine will host Sensu's
server, API, and GUI.

For this example lets assume the following:

* Your future Sensu node has name `sensu.example.org` and it's IP is 10.0.0.1
* A node which will be monitored has name `myserver.example.org` and IP 10.0.0.2
* You are interested in one check plugin `check-disk.rb`
* You are interested in one metric plugin `metric-sysopia.rb`

In your own cookbook include the default `gna-sensu-wrapper` recipe:

```ruby
include_recipe "gna-sensu-wrapper"
```
You can also include the recipe into a node's or a role's `run_list`:

```json
{"run_list":
  ["recipe[gna-sensu-wrapper]"]
}
```

Use knife to create a data bags for `sensu` and `sensu_checks`.

```bash
$ knife data bag create sensu
$ knife data bag create sensu_checks
```

In `sensu` data bag create items `config` and `handlers`. In `sensu_checks`
create items corresponding to your checks in our case `check-disk`.

```bash
$ knife data bag create sensu config
$ knife data bag create sensu handlers
$ knife data bag create sensu ssl
$ knife data bag create sensu_checks check-disk
```

### Item sensu -> config

Item `config` contains general information about Sensu:

```json
{
  "id": "config",
  "master_address": "10.0.0.1",
  "uchiwa_user": "uchiwa",
  "uchiwa_password": "secret",
  "additional": {
    "keepalive": {
      "handlers": ["ponymailer"]
    }
  },
  "sensu.example.com": {
    "roles": ["sensu", "server"]
  },
  "eol-db-master1.si.edu": {
    "roles": ["server"]
  }
}
```
| Parameter      | Description                                                |
|----------------|------------------------------------------------------------|
| master_address | Tells where to install sensu server and where client listen|
| uchiva_user    | User for web interface (uchiva app)                        |
| uchiva_password| Password for web interface (uchiva app)                    |
| keepalive      | Instrucions for built-in keepalive check (sets handlers)   |

Config data bag also assigns roles to nodes. Later you can assign plugins to
work only for specific role/roles.

### Item sensu -> handlers

Item `handlers` contains configuration about handlers of the system. In our
case `ponymailer`.

```json
{
  "id": "handlers",
  "ponymailer": {
    "recipients": [
      "user1@example.org",
      "user2@example.org",
      "user3@example.org"
    ],
    "from": "alerts@example.org",
    "fromname": "Sensu alert",
    "hostname": "localhost",
    "port": 25
  },
  "postfix": {
    "mydomain": "sensu.example.org",
    "myorigin": "sensu.example.org",
    "smtp_use_tls": "no",
    "smtpd_use_tls": "no"
  },
  "sysopia": {
    "mysqlini": "/etc/sensu/my_sysopia.cnf"
  }
}
```
Data from this file set parameters for handlers

### Item sensu -> ssl

Sensu uses ssl protocol to communicate between servers. To generate ssl
databag in your file system you can use a [script][4] provided in `sensu`
cookbook:

### Item sensu_checks -> check-disk

Item `check-disk` explains how this particular check should be used with
Sensu clients.

```json
{
  "id": "check_disk",
  "command": "check-disk.rb -c 95 -w 85",
  "handlers": [ "ponymailer" ],
  "subscribers": [ "all" ]
  "interval": 3600
}
```
Read [Sensu documentation][5] how to configure checks and handlers

Contributing
------------
1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write your change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

License and Authors
-------------------

Authors: [Dmitry Mozzherin][6], [Jeremy Rice][7]


Copyright: 2015, [Marine Biological Laboratory][8]

Licensed under the [MIT License][9]

[1]: https://github.com/gnames/gna-sensu-wrapper-cookbook/tree/master/files/default/plugins
[2]: https://github.com/gnames/gna-sensu-wrapper-cookbook/tree/master/files/default/handlers
[3]: https://github.com/sensu/sensu-community-plugins.git
[4]: https://github.com/sensu/sensu-chef/blob/master/examples/ssl/generate_databag.rb
[5]: http://sensuapp.org/docs
[6]: https://github.com/dimus
[7]: https://github.com/jrice
[8]: http://mbl.edu
[9]: https://github.com/EOL/eol-users-cookbook/blob/master/LICENSE
