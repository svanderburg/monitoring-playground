Monitoring playground
=====================
This repository is the result of my (ongoing) learning experiences building a
simple monitoring and alerting system. It contains collection of configuration
files, scripts and deployment recipes that collect all my findings.

To develop this monitoring system, I have used the following technologies:

* [Telegraf](https://www.influxdata.com/time-series-platform/telegraf)
* [InfluxDB](https://www.influxdata.com/products/influxdb)
* [Kapacitor](https://www.influxdata.com/time-series-platform/kapacitor)
* [Alerta](https://alerta.io)
* [Grafana](https://grafana.com)

Implemented features
====================
* Fully automated deployment of the entire system, using [Nix](http://nixos.org)
  related deployment technologies
* Kapacitor TICK scripts that trigger alerts when we have excessive CPU or RAM consumption
* Grafana dashboards for visualizing the CPU and memory consumption graphs
* Test scripts for validating the CPU and memory alerting TICK scripts with a
  minimum number of data points
* Non-interactive automated test procedure for the TICK scripts
* Automated Grafana dashboard deployments
* Automated TICK script deployments

Deployment
==========
To deploy this example system you need to use
[NixOps](https://github.com/nixos/nixops) and
[Disnix](https://github.com/svanderburg/disnix).

The `deployment/DistributedDeployment/` sub folder contains Nix expressions for
NixOps to deploy virtual machines and Disnix to deploy services to machines.

We can deploy a network of bare NixOS machines managed with VirtualBox, as
follows:

```bash
$ nixops create network.nix network-virtualbox.nix -d test
$ nixops deploy -d test
```

and deploy all services (processes, databases, web applications) to these
virtual machines as follows:

```bash
$ export NIXOPS_DEPLOYMENT=test
$ disnixos-env -s services.nix -n network.nix -d distribution.nix
```

By default, the system will deploy Kapacitor stream tasks to analyze data and
trigger alerts. It is also possible to deploy batch tasks instead, by adding
an additional parameter:

```bash
$ disnixos-env -s services.nix -n network.nix -d distribution.nix --extra-params '{ useStreamTasks = false; }'
```

Usage
=====
The system provides two front-end applications that can be accessed as follows:

* Grafana dashboard: `http://test1:3000`
* The Alerting web user interface: `http://test1`

Deploying TICK scripts
======================
Putting TICK scripts in the `tasks/stream/load/tasks` sub directory or
`tasks/batch/load/tasks` and carrying out the Disnix deployment procedure causes
Kapacitor to get reconfigured to run all updated TICK scripts.

Deploying Grafana dashboards
============================
Dashboards can be automatically deployed by putting their JSON configuration
files in the a sub folder in the `dashboards/` directory.

Running experiments
===================
The `test2` machine is a machine that only runs Telegraf. It can be used to run
experiments on.

We can connect to this machine as follows:

```bash
$ nixops ssh -d test test2
```

With the following command, we can hog the CPU:

```bash
$ dd if=/dev/zero of=/dev/null
```

With the following command, we can fill the RAM:

```bash
</dev/zero head -c $((1024**3*3)) | tail # 3 GiB of RAM
```

Running the test scripts non-interactively
==========================================
It is also possible to deploy a minimal version of the system that makes it
possible to run the test scripts:

```bash
$ nix-build release.nix -A tests
```

The above derivation uses the NixOS test driver.

Creating a configurable dashboard with a panel
==============================================
This is how I have created the dashboard with the CPU activity and memory usage
panels.

Creating a new dashboard
------------------------
* Go to the dashboard management screen. Pick the icon on panel left.
  Dashboards -> Manage
* Click on the button: 'New Dashboard'

Configuring the dashboard settings
----------------------------------
* Click on the 'Dashboard settings' on the top right panel
* In the `General` screen, configure a 'Name', such as: `System metrics`

Configuring dashboard variables
-------------------------------
Go to the tab: 'Variables' and configure variables with the following
properties:

host:

* Name: `host`
* Data source: `sysmetricsdb`
* Refresh: `On Time Range Change`
* Query: `SHOW TAG VALUES FROM "system" WITH KEY = "host"`

cpu:

* Name: `cpu`
* Data source: `sysmetricsdb`
* Refresh: `On Time Range Change`
* Query: `SHOW TAG VALUES FROM "cpu" WITH KEY = "cpu" WHERE host =~ /$host/`

Create a new panel (CPU utilization):
-------------------------------------
Construct a query with the following properties:

* FROM: `default` `cpu` `WHERE` `host` `=~` `/^host$/` `AND` `cpu` `=~` `/^cpu$/`
* SELECT: `field(usage_active)` `mean()` `alias(active)`
* GROUP BY: `time($__interval)` `fill(linear)`
* FORMAT AS: `Time series`

Go to the 'Panel' tab on the top right:
* Panel title: `CPU utilization`

Go to the 'Field' tab on the top right:
* Unit: `Percent (0-100)`

Create a new panel (Available memory):
--------------------------------------
Construct a query with the following properties:

* FROM: `default` `mem` `WHERE` `host` `=~` `/^host$/`
* SELECT: `field(available_percent)` `mean()` `alias(available)`
* GROUP BY: `time($__interval)` `fill(linear)`
* FORMAT AS: `Time series`

Go to the 'Panel' tab on the top right:
* Panel title: `Available memory`

Go to the 'Field' tab on the top right:
* Unit: `Percent (0-100)`

Saving a JSON representation of the dashboard for automatic deployment
----------------------------------------------------------------------
To allow the dashboard to be deployed the next time you deploy the system from
scratch, you should export a representation to JSON and put that configuration
file in the `dashboards` folder:

* First save the dashboard
* Click on the 'Share dashboard` icon on the top left panel (third icon)
* Click on the 'Export' tab
* Click on the 'Save to file' button and save the JSON file
* Put the JSON file into the dashboards deployment directory, such as
  `dashboards/sysmetrics/sysmetrics.json`

License
=======
The deployment recipes and configuration files in this repository are
[MIT licensed](./LICENSE.txt).
