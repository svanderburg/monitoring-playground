{stdenv, writeScriptBin, influxdb, alerta, jq}:
{sysmetricsdb, alerta-server}:

let
  influxCmd = "influx -database ${sysmetricsdb.name} -host ${sysmetricsdb.target.properties.hostname} -port ${toString sysmetricsdb.target.container.influxdbHttpPort}";
  name = "test-cpu-alerts";
in
writeScriptBin name ''
  #! ${stdenv.shell} -e
  export PATH=${influxdb}/bin:${alerta}/bin:${jq}/bin:$PATH

  # Insert data point into the system measurement, so that the dashboard allows you to pick a host
  ${influxCmd} -execute "INSERT system,host=test2 load=0"

  # Configure the Alert CLI to connect to our deployed alerta-server instance
  export ALERTA_ENDPOINT="http://${alerta-server.target.properties.hostname}:${toString alerta-server.port}"

  # Offset back in time where the data points start (one hour in the past)
  offset="$(($(date +%s) - 3600))"

  convertToNS()
  {
      local timeinsecs="$1"
      echo "''${timeinsecs}000000000"
  }

  testCPUAlert()
  {
      local active="$1"
      local window="$2"
      local severity="$3"

      # The idea of this test is to generate three data points. The first two
      # are on the boundaries of the time window forcing the mean value to
      # become the specified active value.
      # The third data point is deliberately outside the time window to force
      # the alert node to evaluate the mean value.

      ${influxCmd} -execute "INSERT cpu,cpu=cpu0,host=test2 usage_active=$active $(convertToNS $offset)"
      offset=$((offset + $window))
      ${influxCmd} -execute "INSERT cpu,cpu=cpu0,host=test2 usage_active=$active $(convertToNS $offset)"
      offset=$((offset + $window))
      ${influxCmd} -execute "INSERT cpu,cpu=cpu0,host=test2 usage_active=$active $(convertToNS $offset)" # deliberately outside the time window
      offset=$((offset + $window))

      sleep 1
      actualSeverity=$(alerta --output json query | jq '.[0].severity')

      if [ "\"$severity\"" != "$actualSeverity" ]
      then
          echo "Expected severity: \"$severity\", but we got: $actualSeverity" >&2
          false
      else
          echo "Severity level is: $actualSeverity" >&2
      fi
  }

  testCPUAlert 100 60 critical
  testCPUAlert 80 60 warning
  testCPUAlert 0 60 ok
''
