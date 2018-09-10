#! /usr/bin/env ruby
app_name = ARGV[0]
app_short = ARGV[1]
app_schema = ARGV[2]
app_label = ARGV[3]

@app_name = app_name
@app_short = app_short
@app_schema = app_schema
@app_label = app_label

unless ARGV.length == 4
  puts "Incorrect number of arguments. Remember to quote the app label arg."
  exit
end

@app_name_camelized = app_name_camelized = app_name.split('_').collect(&:capitalize).join

unless Dir.entries('.').include? 'db'
  puts "Run the script from the base app directory"
  exit
end

appdir = "db/app_specific/#{app_name}"

appconfig = "db/app_configs/#{app_name}"
appsyncdir = "db/app_specific/sync-process/#{app_name}-sync"


if Dir.exist? appdir
  puts"#{appdir} directory already exists"
else
  puts "Created directory #{appdir}"
  Dir.mkdir appdir
end

if Dir.exist? appsyncdir
  puts"#{appsyncdir} directory already exists"
else
  puts "Created directory #{appsyncdir}"
  Dir.mkdir appsyncdir
end


def sub_app text
  text.gsub('{{app_name}}', @app_name)
    .gsub('{{app_short}}', @app_short)
    .gsub('{{app_schema}}', @app_schema)
    .gsub('{{app_label}}', @app_label)
    .gsub('{{AppName}}', @app_name_camelized )
    .gsub('{{app_name_uc}}', @app_name.upcase)
end

puts "Creating config.json"
res = File.read("db/app_configs/participant_questions_generator_config.json")
res = sub_app res
fn = "db/app_configs/#{app_name}_config.json"
File.open(fn, 'w') { |f| f.write(res)  }

puts "Creating sync"
Dir.glob("db/app_specific/sync-process/participant_questions_generator-sync/*").each do |name|

  orig_name = name.split('/').last
  fn = File.join(appsyncdir, orig_name)

  puts "Generating #{name}"
  res = File.read(name)

  res = sub_app res
  File.open(fn, 'w') { |f| f.write(res)  }
  puts "Generated #{fn}"

end

Dir.glob("db/app_specific/participant_questions_generator/*/*.sql").each do |name|

  orig_name = name.split('/')[-2..-1]
  fn = File.join(appdir, orig_name[0], orig_name[1])

  target_dir = File.join(appdir, orig_name[0])
  Dir.mkdir target_dir unless Dir.exist? target_dir

  puts "Generating #{name}"
  res = File.read(name)

  res = sub_app res
  File.open(fn, 'w') { |f| f.write(res)  }
  puts "Generated #{fn}"

end
