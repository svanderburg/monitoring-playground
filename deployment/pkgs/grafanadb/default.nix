{stdenv}:
{postgresqlUsername, postgresqlPassword}:

stdenv.mkDerivation {
  name = "grafanadb";
  buildCommand = ''
    mkdir -p $out/postgresql-databases
    cat > $out/postgresql-databases/grafanadb.sql << "EOF"
    DO
    $do$
    BEGIN
        IF NOT EXISTS (
            SELECT *
            FROM pg_catalog.pg_user
            WHERE usename = '${postgresqlUsername}') THEN

            CREATE USER ${postgresqlUsername} WITH PASSWORD '${postgresqlPassword}';
            ALTER DATABASE grafanadb OWNER TO ${postgresqlUsername};
        END IF;
    END
    $do$;
    EOF
  '';
}
