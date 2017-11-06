#! /bin/bash

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]
  then
    echo
    echo "Produces SQL to simplify the creation or destruction of DBA defined tables used by Zeus."
    echo
    echo "Usage:"
    echo
    echo "db/table_generators/generate.sh <generator_name> create|drop <pluralized_table_name> [field_names...]"
    echo
    echo "    generator_name          activity_logs_table, external_identifiers_table"
    echo "    create|drop             create or drop the tables, triggers and constraints"
    echo "    pluralized_table_name   name of primary table name to be used."
    echo "                            'activity_logs_table' generator, will automatically prefix name with activity_log_"
    echo "    field_names             additional fields for the tables."
    echo
    exit 1
fi

if [ "$3" = "create" ]
  then
    mode=false
fi
if [ "$3" = "drop" ]
  then
    mode=:drop
fi

if [ -z "$mode" ]
  then
    echo "Incorrect value for create|drop mode. Run without arguments to see usage."
fi

field_names="${@: 4}"

ruby -e "require './db/table_generators/$1.rb'; ext = '$field_names'.split(' '); TableGenerators.$1('$2', $mode, *ext )"
