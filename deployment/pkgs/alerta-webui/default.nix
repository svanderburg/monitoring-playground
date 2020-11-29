{stdenv, fetchurl}:
{alerta-server}:

stdenv.mkDerivation {
  name = "alerta-webui-8.0.1";
  src = fetchurl {
    url = https://github.com/alerta/alerta-webui/releases/download/v8.0.1/alerta-webui.tar.gz;
    sha256 = "12924pmkwn3v1vwdgrgg3n94w74fvq64a1w0wfc671ibkr355nwa";
  };
  buildCommand = ''
    tar xfv $src
    mkdir -p $out/webapps
    mv dist/* $out/webapps

    # Generate config file
    cat > $out/webapps/config.json <<EOF
    {
        "endpoint": "http://${alerta-server.target.properties.hostname}:${toString alerta-server.port}"
    }
    EOF
  '';
}
