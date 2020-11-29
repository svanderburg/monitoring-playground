{createManagedProcess, runCommand, writeTextFile, stateDir, grafana}:
{instanceSuffix ? "", instanceName ? "grafana${instanceSuffix}", httpPort ? 3000, domain ? "localhost"}:
{metricsdb, grafanadb}:

let
  dataDir = "${stateDir}/lib/${instanceName}";

  datasourceFile = writeTextFile {
    name = "datasource.yaml";
    text = ''
      apiVersion: 1

      deleteDatasources:
        - name: ${metricsdb.name}
          orgId: 1

      datasources:
        - name: ${metricsdb.name}
          type: influxdb
          url: http://${metricsdb.target.properties.hostname}:${toString metricsdb.target.container.influxdbHttpPort}
          database: ${metricsdb.name}
          user: ${metricsdb.influxdbUsername}
          password: ${metricsdb.influxdbPassword}
          orgId: 1
    '';
  };

  dashboardsFile = writeTextFile {
    name = "dashboards.yaml";
    text = ''
      apiVersion: 1

      providers:
        - name: 'default dashboard provider'
          orgId: 1
          type: file
          updateIntervalSeconds: 30
          options:
              path: ${../../../dashboards}
              foldersFromFilesStructure: true
    '';
  };

  provisionConfDir = runCommand "grafana-provisioning" {} ''
    mkdir -p $out/datasources $out/dashboards
    ln -sf ${datasourceFile} $out/datasources/datasource.yaml
    ln -sf ${dashboardsFile} $out/dashboards/dashboards.yaml
  '';
in
createManagedProcess {
  name = instanceName;
  inherit instanceName;
  initialize = ''
    ln -sf ${grafana}/share/grafana/conf ${dataDir}
  '';
  environment = {
    GF_PATHS_DATA = dataDir;
    GF_PATHS_PLUGINS = "${dataDir}/plugins";
    GF_PATHS_LOGS = "${dataDir}/log";
    GF_PATHS_PROVISIONING = provisionConfDir;

    GF_SERVER_PROTOCOL = "http";
    GF_SERVER_HTTP_PORT = httpPort;
    GF_SERVER_DOMAIN = domain;
    GF_SERVER_ROOT_URL = "%(protocol)s://%(domain)s:%(http_port)s/";
    GF_SERVER_STATIC_ROOT_PATH = "${grafana}/share/grafana/public";

    GF_DATABASE_TYPE = "postgres";
    GF_DATABASE_HOST = "${grafanadb.target.properties.hostname}:${toString grafanadb.target.container.postgresqlPort}";
    GF_DATABASE_NAME = grafanadb.name;
    GF_DATABASE_USER = grafanadb.postgresqlUsername;
    GF_DATABASE_PASSWORD = grafanadb.postgresqlPassword;
  };
  foregroundProcess = "${grafana}/bin/grafana-server";
  args = [ "-homepath" dataDir ];
  directory = dataDir;
  user = instanceName;

  credentials = {
    groups = {
      "${instanceName}" = {};
    };
    users = {
      "${instanceName}" = {
        homeDir = dataDir;
        createHomeDir = true;
        group = instanceName;
        description = "Grafana user";
      };
    };
  };

  overrides = {
    sysvinit.runlevels = [ 3 4 5 ];
  };
}
