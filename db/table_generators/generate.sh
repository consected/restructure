#! /bin/bash

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]
  then
    echo
    echo "Produces SQL to simplify the creation or destruction of DBA defined tables used by Zeus."
    echo
    echo "Usage:"
    echo
    echo "db/table_generators/generate.sh <generator_name> create|drop <pluralized_table_name> <activity_logs_base_name> [field_names...]"
    echo
    echo "    generator_name            activity_logs_table, external_identifiers_table, dynamic_models_table, admin_history_table, item_history_table"
    echo "    create|drop               create or drop the tables, triggers and constraints"
    echo "    pluralized_table_name     name of primary table name to be used."
    echo "                              'activity_logs_table' generator, will automatically prefix name with activity_log_"
    echo "    activity_logs_base_name   for activity logs table only, the table name being referenced by activity logs "
    echo "                              e.g. 'player_contacts' when 'pluralized_table_name' is 'player_contact_phones'"
    echo "                              e.g. 'player_infos' when 'pluralized_table_name' is 'player_infos'"
    echo "    field_names               additional fields for the tables."
    echo
    exit 1
fi

mparam=$2

if [ "$mparam" = "create" ]
  then
    mode=false
fi
if [ "$mparam" = "drop" ]
  then
    mode=:drop
fi


if [ -z "$mode" ]
  then
    echo "Incorrect value for create|drop mode. Run without arguments to see usage."
fi


if [ "$1" = "activity_logs_table" ]
  then
    field_names="${@: 5}"
    ruby -e "require './db/table_generators/$1.rb'; ext = '$field_names'.split(' '); TableGenerators.$1('$3', '$4', $mode, *ext )"
else
    field_names="${@: 4}"
    ruby -e "require './db/table_generators/$1.rb'; ext = '$field_names'.split(' '); TableGenerators.$1('$3', $mode, *ext )"
fi
