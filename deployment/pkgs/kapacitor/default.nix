{createManagedProcess, kapacitor, stateDir}:
{instanceSuffix ? "", instanceName ? "kapacitor${instanceSuffix}", configFile}:

let
  dataDir = "${stateDir}/lib/${instanceName}";
in
createManagedProcess {
  name = "kapacitor";
  inherit instanceName;
  foregroundProcess = "${kapacitor}/bin/kapacitord";
  args = [ "-config" configFile ];
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
        description = "Kapacitor user";
      };
    };
  };

  overrides = {
    sysvinit.runlevels = [ 3 4 5 ];
  };
}
