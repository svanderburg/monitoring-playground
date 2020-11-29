{infrastructure}:

{
  # Container providers
  influxdb = [ infrastructure.localhost ];
  postgresql = [ infrastructure.localhost ];
  apache = [ infrastructure.localhost ];

  # Services
  sysmetricsdb = [ infrastructure.localhost ];
  grafanadb = [ infrastructure.localhost ];
  grafana = [ infrastructure.localhost ];
  kapacitor = [ infrastructure.localhost ];
  alertadb = [ infrastructure.localhost ];
  alerta-server = [ infrastructure.localhost ];
  alerta-webui = [ infrastructure.localhost ];
}
