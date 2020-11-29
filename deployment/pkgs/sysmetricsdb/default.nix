{stdenv}:
{influxdbUsername, influxdbPassword}:

stdenv.mkDerivation rec {
  name = "sysmetricsdb";
  buildCommand = ''
    mkdir -p $out/influx-databases
    cat > $out/influx-databases/sysmetrics.influxql <<EOF
    # DDL
    CREATE DATABASE ${name}
    CREATE USER ${influxdbUsername} WITH PASSWORD '${influxdbPassword}'
    GRANT ALL PRIVILEGES TO ${influxdbUsername}
    EOF
  '';
}
