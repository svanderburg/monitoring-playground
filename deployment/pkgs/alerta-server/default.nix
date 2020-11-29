{createManagedProcess, alerta-server}:
{ instanceSuffix ? "", instanceName ? "alerta-server${instanceSuffix}"
, port
, bindIP ? "127.0.0.1"
, configFile
}:

createManagedProcess {
  name = instanceName;
  inherit instanceName;
  foregroundProcess = "${alerta-server}/bin/alertad";
  args = [ "run" "--port" port "--host" bindIP ];
  environment = {
    ALERTA_SVR_CONF_FILE = configFile;
  };
  user = instanceName;

  credentials = {
    groups = {
      "${instanceName}" = {};
    };
    users = {
      "${instanceName}" = {
        group = instanceName;
        description = "Alerta server user";
      };
    };
  };

  overrides = {
    sysvinit.runlevels = [ 3 4 5 ];
  };
}
