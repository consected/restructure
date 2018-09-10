app_name = ARGV[0]
app_short = ARGV[1]
app_label = ARGV[2]
unless ARGV.length == 3
  puts "Incorrect number of arguments. Remember to quote the app label arg."
  exit
end

unless Dir.entries('.').include? 'db'
  puts "Run the script from the base app directory"
  exit
end

appdir = "db/app_specific/#{app_name}"

if Dir.exist? appdir
  puts"#{appdir} directory already exists"
  exit
end

Dir.mkdir appdir

Dir.glob("db/app_specific/participant_questions_generator/*.sql").each do |name|
  if name ~= /^\d+-.sql$/
    puts "Generating #{name}"
    res = File.read(name)

    res = res.gsub('{{app_name}}', app_name).gsub('{{app_short}}', app_short).gsub('{{app_label}}', app_label).gsub('{{AppName}}', app_name.camelize)
    orig_name = name.split('/').last
    fn = File.join(appdir, orig_name)
    File.open(fn, 'w') { |f| f.write(res)  }

  end
end
