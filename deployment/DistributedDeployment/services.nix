{ pkgs, system, distribution, invDistribution
, stateDir ? "/var"
, logDir ? "${stateDir}/log"
, runtimeDir ? "${stateDir}/run"
, cacheDir ? "${stateDir}/cache"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false
, processManager ? "systemd"
, nix-processmgmt ? ../../../nix-processmgmt
, useStreamTasks ? true
}:

let
  ids = if builtins.pathExists ./ids.nix then (import ./ids.nix).ids else {};

  sharedConstructors = import "${nix-processmgmt}/examples/service-containers-agnostic/constructors.nix" {
    inherit pkgs stateDir logDir runtimeDir cacheDir tmpDir forceDisableUserChange processManager ids;
  };

  constructors = import ../top-level/constructors.nix {
    inherit pkgs system stateDir logDir runtimeDir tmpDir forceDisableUserChange processManager nix-processmgmt ids;
  };

  processType = import "${nix-processmgmt}/nixproc/derive-dysnomia-process-type.nix" {
    inherit processManager;
  };
in
rec {
  influxdb = sharedConstructors.simpleInfluxdb {
    type = processType;
    properties = {
      requiresUniqueIdsFor = [ "uids" "gids" ];
    };
  };

  postgresql = sharedConstructors.postgresql {
    type = processType;
    properties = {
      requiresUniqueIdsFor = [ "uids" "gids" ];
      timeout = 20;
    };
  };

  apache = sharedConstructors.simpleWebappApache {
    type = processType;
    serverAdmin = "root@localhost";
    documentRoot = "${stateDir}/www";
    properties = {
      requiresUniqueIdsFor = [ "uids" "gids" ];
    };
  };

  sysmetricsdb = rec {
    name = "sysmetricsdb";
    influxdbUsername = name;
    influxdbPassword = name;
    pkg = constructors.sysmetricsdb {
      inherit influxdbUsername influxdbPassword;
    };
    type = "influx-database";
  };

  telegraf = {
    name = "telegraf";
    pkg = constructors.simpleSysmetricsTelegraf {};
    dependsOn = {
      metricsdb = sysmetricsdb;
    };
    type = processType;
    requiresUniqueIdsFor = [ "uids" "gids" ];
  };


  grafanadb = rec {
    name = "grafanadb";
    postgresqlUsername = name;
    postgresqlPassword = name;
    pkg = constructors.grafanadb {
      inherit postgresqlUsername postgresqlPassword;
    };
    type = "postgresql-database";
  };

  grafana = {
    name = "grafana";
    pkg = constructors.grafana {};
    dependsOn = {
      metricsdb = sysmetricsdb;
      inherit grafanadb;
    };
    type = processType;
    requiresUniqueIdsFor = [ "uids" "gids" ];
  };

  alertadb = rec {
    name = "alertadb";
    postgresqlUsername = name;
    postgresqlPassword = name;
    pkg = constructors.alertadb {
      inherit postgresqlUsername postgresqlPassword;
    };
    type = "postgresql-database";
  };

  alerta-server = rec {
    name = "alerta-server";
    port = 5000;
    environment = "Development";
    pkg = constructors.simple-alerta-server {
      inherit port;
    };
    dependsOn = {
      inherit alertadb;
    };
    connectsTo = {
      inherit alerta-webui;
    };
    type = processType;
    requiresUniqueIdsFor = [ "uids" "gids" ];
  };

  alerta-webui = {
    name = "alerta-webui";
    pkg = constructors.alerta-webui;
    dependsOn = {
      inherit alerta-server;
    };
    type = "apache-webapplication";
  };

  kapacitor = {
    name = "kapacitor";
    pkg = constructors.alerting-kapacitor {
      inherit useStreamTasks;
    };
    dependsOn = {
      defaultDatabase = sysmetricsdb;
      inherit alerta-server;
    };
    type = processType;
    requiresUniqueIdsFor = [ "uids" "gids" ];
  };

  cputestscript = {
    name = "cputestscript";
    pkg = constructors.cputestscript;
    dependsOn = {
      inherit sysmetricsdb alerta-server;
    };
    type = "package";
  };

  memtestscript = {
    name = "memtestscript";
    pkg = constructors.memtestscript;
    dependsOn = {
      inherit sysmetricsdb alerta-server;
    };
    type = "package";
  };
}
