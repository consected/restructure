DO
$body$
BEGIN

   IF NOT EXISTS (
      SELECT *
      FROM   pg_catalog.pg_roles
      WHERE  rolname = 'restradmin') THEN
      create role restradmin;
      ALTER ROLE restradmin WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION ;
   END IF;


   IF NOT EXISTS (
      SELECT *
      FROM   pg_catalog.pg_roles
      WHERE  rolname = 'restrapp') THEN

        CREATE ROLE restrapp;
        ALTER ROLE restrapp WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION;
   END IF;

END
$body$;
