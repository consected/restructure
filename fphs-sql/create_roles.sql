DO
$body$
BEGIN

   IF NOT EXISTS (
      SELECT *
      FROM   pg_catalog.pg_roles
      WHERE  rolname = 'fphs') THEN
      create role fphs;
      ALTER ROLE fphs WITH SUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION ;
   END IF;

   IF NOT EXISTS (
      SELECT *
      FROM   pg_catalog.pg_roles
      WHERE  rolname = 'fphsusr') THEN

      create role fphsusr;
      ALTER ROLE fphsusr WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOREPLICATION;
   END IF;

   IF NOT EXISTS (
      SELECT *
      FROM   pg_catalog.pg_roles
      WHERE  rolname = 'fphsadm') THEN

      create role fphsadm;
      ALTER ROLE fphsadm WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOREPLICATION;
   END IF;

   IF NOT EXISTS (
      SELECT *
      FROM   pg_catalog.pg_roles
      WHERE  rolname = 'fphsetl') THEN

        CREATE ROLE fphsetl;
        ALTER ROLE fphsetl WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOREPLICATION;
   END IF;

END
$body$;
