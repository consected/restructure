DO
$body$
BEGIN


   IF NOT EXISTS (
      SELECT *
      FROM   pg_catalog.pg_roles
      WHERE  rolname = 'fphsusr') THEN

      create role fphsusr;
      ALTER ROLE fphsusr WITH INHERIT NOCREATEROLE NOCREATEDB NOLOGIN ;
   END IF;

   IF NOT EXISTS (
      SELECT *
      FROM   pg_catalog.pg_roles
      WHERE  rolname = 'fphsrailsapp') THEN

      create user fphsrailsapp role fphsusr;
      ALTER user fphsrailsapp WITH INHERIT NOCREATEROLE NOCREATEDB LOGIN;
   END IF;

   IF NOT EXISTS (
      SELECT *
      FROM   pg_catalog.pg_roles
      WHERE  rolname = 'fphsadm') THEN

      create role fphsadm;
      ALTER ROLE fphsadm WITH INHERIT NOCREATEROLE NOCREATEDB NOLOGIN ;
   END IF;

   IF NOT EXISTS (
      SELECT *
      FROM   pg_catalog.pg_roles
      WHERE  rolname = 'fphsetl') THEN

        CREATE ROLE fphsetl;
        ALTER ROLE fphsetl WITH INHERIT NOCREATEROLE NOCREATEDB NOLOGIN ;
   END IF;

END
$body$;
