# Adapted from code at: http://eewang.github.io/blog/2013/07/29/how-to-use-rake-tasks-to-generate-migration-sql/

namespace :db do
  [ :migrate, :rollback ].each do |n|
    namespace n do |migration_task|

      original_task = ""
      migration_task.instance_variable_get("@scope").each {|ot|
        original_task = ":#{original_task}" unless original_task.blank?
        original_task = "#{ot}#{original_task}"
      }

      [:with_sql, :to_sql ].each do |t|


        desc "Run migration, and generated SQL" if t == :with_sql
        desc "Generate migration SQL" if t == :to_sql
        task t => :environment do |sql_task|

          ActiveRecord::Base.connection.class.class_eval do
            # alias the adapter's execute for later use
            alias :old_execute :execute

            # It is necessary to run the SQL, otherwise the actual results generated
            # may not actually reflect a real schema, especially if there is hand crafted
            # SQL that checks for the existence of tables (for example) created earlier in the
            # set of migrations.
            RUN_SQL = true #sql_task.name.ends_with?("with_sql")

            # define our own execute
            def execute(sql, name = nil)
              # check for some DDL and DML statements
              puts "Running sql? #{RUN_SQL}"

              if /(create |alter |drop |insert |delete |update )/i.match sql.squish
                File.open(SQL_FILENAME, 'a') { |f| f.puts "#{sql};\n" }
                puts "Rails.env: #{Rails.env} - #{ENV['FPHS_POSTGRESQL_SCHEMA']}"
                old_execute sql, name if RUN_SQL
              else
                # pass everything else to the aliased execute
                puts "------------- (#{name}) ---------------"
                puts sql || ''
                puts "-------------                        ---------------"
                old_execute sql, name if RUN_SQL
              end
            end

          end

          # create or delete content of migration.sql

          hostname = ENV['EXTNAME']
          filename = nil
          case original_task
          when "db:migrate"
            filename = "db/dumps/migrate-#{hostname}-#{ENV['VER']}/upgrade.sql"
          when "db:rollback"
            filename = "db/dumps/migrate-#{hostname}-#{ENV['VER']}/rollback.sql"
          else
            raise "unknown migration type #{original_task}"
          end

          SQL_FILENAME = filename
          File.open(SQL_FILENAME, 'w') { |f| f.puts "-- Script created @ #{Time.now}" }
          sqlfile = "set search_path=#{ENV['SCHEMA']}; \n begin;  "
          File.open(SQL_FILENAME, 'a') { |f| f.puts "#{sqlfile};\n" }
          puts    "Created file: #{sqlfile}"

          # invoke the normal migration procedure now
          begin
            Rake::Task[original_task].invoke
          rescue => e
            puts e
            puts e.backtrace.join("\n")
            raise e
          end

          sqlfile = "\n#{ENV['APPEND_SQL']}\n commit; "
          File.open(SQL_FILENAME, 'a') { |f| f.puts "#{sqlfile};\n" }

          puts "Ran #{original_task} and wrote sql to #{filename}"
        end


      end
    end
  end

end
