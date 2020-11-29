{createManagedProcess, stdenv, writeTextFile, alerta-server}:
{ instanceSuffix ? "", instanceName ? "alerta-server${instanceSuffix}"
, port
, bindIP ? "0.0.0.0"
, corsOrigins ? [ "http://localhost" "http://localhost:${toString port}" ]
}:
{alertadb, alerta-webui ? null}:

let
  allCorsOrigins = corsOrigins
    ++ stdenv.lib.optional (alerta-webui != null && alerta-webui.targets != []) "http://${alerta-webui.target.properties.hostname}${stdenv.lib.optionalString (alerta-webui.target.container.port != 80) (":" + (toString alerta-webui.target.container.port))}";
in
import ../alerta-server {
  inherit createManagedProcess alerta-server;
} {
  inherit instanceSuffix instanceName port bindIP;
  configFile = writeTextFile {
    name = "alertad.conf";
    text = ''
      CORS_ORIGINS = [ ${stdenv.lib.concatMapStringsSep ", " (corsOrigin: "\"${corsOrigin}\"") allCorsOrigins} ]
      DATABASE_URL = 'postgresql://${alertadb.postgresqlUsername}:${alertadb.postgresqlPassword}@${alertadb.target.properties.hostname}/${alertadb.name}'
      DATABASE_NAME = '${alertadb.name}'
    '';
  };
}
