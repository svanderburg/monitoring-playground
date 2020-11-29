{createManagedProcess, writeTextFile, telegraf}:
{instanceSuffix ? "", instanceName ? "telegraf${instanceSuffix}"}:
{metricsdb}:

import ../telegraf {
  inherit createManagedProcess telegraf;
} {
  inherit instanceSuffix instanceName;

  configFile = writeTextFile {
    name = "telegraf.conf";
    text = ''
      [agent]
        interval = "10s"

      [[outputs.influxdb]]
        urls = [ "http://${metricsdb.target.properties.hostname}:${toString metricsdb.target.container.influxdbHttpPort}" ]
        database = "${metricsdb.name}"
        username = "${metricsdb.influxdbUsername}"
        password = "${metricsdb.influxdbPassword}"

      [[inputs.system]]
        # no configuration

      [[inputs.cpu]]
        ## Whether to report per-cpu stats or not
        percpu = true
        ## Whether to report total system cpu stats or not
        totalcpu = true
        ## If true, collect raw CPU time metrics.
        collect_cpu_time = false
        ## If true, compute and report the sum of all non-idle CPU states.
        report_active = true

      [[inputs.mem]]
        # no configuration
    '';
  };
}
