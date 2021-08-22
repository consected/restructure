CREATE OR REPLACE VIEW ml_app.user_app_functional_groups
AS WITH templates AS (
         SELECT users.id AS user_id,
            users.email AS template_name
           FROM ml_app.users
          WHERE users.email::text ~~ '%@template'::text AND NOT COALESCE(users.disabled, false)
        ), roles AS (
         SELECT ur.app_type_id,
            t.template_name,
            ur.role_name
           FROM ml_app.user_roles ur
             JOIN templates t ON ur.user_id = t.user_id AND NOT COALESCE(ur.disabled, false) AND ur.role_name::text !~~ 'email %'::text AND ur.role_name::text !~~ 'sms %'::text
        ), template_roles AS (
         SELECT roles.app_type_id,
            roles.template_name,
            array_agg(roles.role_name) AS role_set
           FROM roles
          GROUP BY roles.app_type_id, roles.template_name
        ), user_role_sets AS (
         SELECT ur.app_type_id,
            ur.user_id,
            array_agg(ur.role_name) AS role_set
           FROM ml_app.user_roles ur
             JOIN ml_app.users u ON ur.user_id = u.id
          WHERE u.email::text !~~ '%template'::text AND NOT COALESCE(u.disabled, false) AND NOT COALESCE(ur.disabled, false)
          GROUP BY ur.app_type_id, ur.user_id
        )
 SELECT DISTINCT urs.app_type_id,
    urs.user_id,
    a.label AS app_name,
    u.email AS user_email,
    COALESCE(rd.name, tr.template_name, '(default user)'::character varying) AS group_name
   FROM user_role_sets urs
     LEFT JOIN template_roles tr ON tr.app_type_id = urs.app_type_id AND tr.role_set <@ urs.role_set
     JOIN ml_app.users u ON urs.user_id = u.id AND NOT COALESCE(u.disabled, false)
     JOIN ml_app.app_types a ON a.id = urs.app_type_id
     LEFT JOIN ml_app.role_descriptions rd ON rd.role_template::text = tr.template_name::text AND rd.app_type_id = urs.app_type_id AND NOT COALESCE(rd.disabled, false)
UNION
 SELECT ur.app_type_id,
    ur.user_id,
    a.label AS app_name,
    u.email AS user_email,
    rd.name AS group_name
   FROM ml_app.user_roles ur
     JOIN ml_app.users u ON ur.user_id = u.id AND NOT COALESCE(u.disabled, false)
     JOIN ml_app.role_descriptions rd ON rd.role_name::text = ur.role_name::text AND rd.app_type_id = ur.app_type_id AND NOT COALESCE(rd.disabled, false)
     JOIN ml_app.app_types a ON a.id = ur.app_type_id
  WHERE u.email::text !~~ '%template'::text AND NOT COALESCE(ur.disabled, false)
  ORDER BY 1, 2, 5;