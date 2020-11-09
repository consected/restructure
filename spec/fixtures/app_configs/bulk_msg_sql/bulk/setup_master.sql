DO
$body$
BEGIN

IF NOT EXISTS (
   SELECT *
   FROM   ml_app.masters
   WHERE  id = -1) THEN

insert into ml_app.masters (id) values (-1);
END IF;

END
$body$;
