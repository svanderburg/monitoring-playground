{infrastructure}:

{
  # Container providers
  influxdb = [ infrastructure.test1 ];
  postgresql = [ infrastructure.test1 ];

  # Services
  sysmetricsdb = [ infrastructure.test1 ];
  kapacitor = [ infrastructure.test1 ];
  alertadb = [ infrastructure.test1 ];
  alerta-server = [ infrastructure.test1 ];

  # Test scripts
  cputestscript = [ infrastructure.test2 ];
  memtestscript = [ infrastructure.test2 ];
}
