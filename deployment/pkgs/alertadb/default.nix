{stdenv}:
{postgresqlUsername, postgresqlPassword}:

stdenv.mkDerivation {
  name = "alertadb";
  buildCommand = ''
    mkdir -p $out/postgresql-databases
    cat > $out/postgresql-databases/alertadb.sql << "EOF"
    DO
    $do$
    BEGIN
        IF NOT EXISTS (
            SELECT *
            FROM pg_catalog.pg_user
            WHERE usename = '${postgresqlUsername}') THEN

            CREATE USER ${postgresqlUsername} WITH PASSWORD '${postgresqlPassword}';
            ALTER DATABASE alertadb OWNER TO ${postgresqlUsername};
        END IF;
    END
    $do$;
    EOF
  '';
}
