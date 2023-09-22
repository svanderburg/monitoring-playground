{ pkgs, system
, stateDir
, runtimeDir
, logDir
, tmpDir
, forceDisableUserChange
, processManager
, ids ? {}
, nix-processmgmt
}:

let
  createManagedProcess = import "${nix-processmgmt}/nixproc/create-managed-process/universal/create-managed-process-universal.nix" {
    inherit pkgs stateDir runtimeDir logDir tmpDir forceDisableUserChange processManager ids;
  };
in
{
  sysmetricsdb = import ../pkgs/sysmetricsdb {
    inherit (pkgs) stdenv;
  };

  simpleSysmetricsTelegraf = import ../pkgs/simple-sysmetrics-telegraf {
    inherit (pkgs) writeTextFile telegraf;
    inherit createManagedProcess;
  };

  grafanadb = import ../pkgs/grafanadb {
    inherit (pkgs) stdenv;
  };

  grafana = import ../pkgs/grafana {
    inherit createManagedProcess stateDir;
    inherit (pkgs) grafana runCommand writeTextFile;
  };

  alerting-kapacitor = import ../pkgs/alerting-kapacitor {
    inherit createManagedProcess stateDir;
    inherit (pkgs) stdenv lib writeTextFile kapacitor;
  };

  alertadb = import ../pkgs/alertadb {
    inherit (pkgs) stdenv;
  };

  simple-alerta-server = import ../pkgs/simple-alerta-server {
    inherit (pkgs) stdenv lib writeTextFile alerta-server;
    inherit createManagedProcess;
  };

  alerta-webui = import ../pkgs/alerta-webui {
    inherit (pkgs) stdenv fetchurl;
  };

  cputestscript = import ../pkgs/cputestscript {
    inherit (pkgs) stdenv writeScriptBin influxdb jq alerta;
  };

  memtestscript = import ../pkgs/memtestscript {
    inherit (pkgs) stdenv writeScriptBin influxdb jq alerta;
  };
}
