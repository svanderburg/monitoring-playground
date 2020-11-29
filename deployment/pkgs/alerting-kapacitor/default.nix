{createManagedProcess, stdenv, writeTextFile, kapacitor, stateDir}:

{ instanceSuffix ? "", instanceName ? "kapacitor${instanceSuffix}"
, hostName ? "localhost"
, port ? 9092
, taskSnapshotInterval ? "1m0s"
, bindIP ? "0.0.0.0"
, useStreamTasks
}:

{alerta-server ? null, defaultDatabase ? null}:

let
  loadDirectory = if useStreamTasks then ../../../tasks/stream/load
    else ../../../tasks/batch/load;

  dataDir = "${stateDir}/lib/${instanceName}";
in
import ../kapacitor {
  inherit createManagedProcess kapacitor stateDir;
} {
  configFile = writeTextFile {
    name = "kapacitord.conf";
    text = ''
      hostname="${hostName}"
      data_dir="${dataDir}"

      [http]
        bind-address = "${bindIP}:${toString port}"
        log-enabled = false
        auth-enabled = false

      [task]
        dir = "${dataDir}/tasks"
        snapshot-interval = "${taskSnapshotInterval}"

      [replay]
        dir = "${dataDir}/replay"

      [storage]
        boltdb = "${dataDir}/kapacitor.db"

      ${stdenv.lib.optionalString (loadDirectory != null) ''
        [load]
          enabled = true
          dir = "${loadDirectory}"
      ''}

      ${stdenv.lib.optionalString (defaultDatabase != null) ''
        [[influxdb]]
          name = "default"
          enabled = true
          default = true
          urls = [ "http://${defaultDatabase.target.properties.hostname}:${toString defaultDatabase.target.container.influxdbHttpPort}" ]
          username = "${defaultDatabase.influxdbUsername}"
          password = "${defaultDatabase.influxdbPassword}"
      ''}

      ${stdenv.lib.optionalString (alerta-server != null) ''
        [alerta]
          enabled = true
          url = "http://${alerta-server.target.properties.hostname}:${toString alerta-server.port}"
          environment = "${alerta-server.environment}"
      ''}
    '';
  };
}
