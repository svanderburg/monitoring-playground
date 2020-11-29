{createManagedProcess, telegraf}:
{instanceSuffix ? "", instanceName ? "telegraf${instanceSuffix}", configFile}:

createManagedProcess {
  name = instanceName;
  inherit instanceName;
  foregroundProcess = "${telegraf}/bin/telegraf";
  args = [ "-config" configFile ];
  user = instanceName;

  credentials = {
    groups = {
      "${instanceName}" = {};
    };
    users = {
      "${instanceName}" = {
        group = instanceName;
        description = "Telegraf user";
      };
    };
  };

  overrides = {
    sysvinit.runlevels = [ 3 4 5 ];
  };
}
