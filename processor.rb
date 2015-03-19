require './settings.rb'
require './library.rb'

settings = Settings.new
library = Library.new(settings)

args = $*
if args.include?("--consolidate")
  puts "consolidating library ... "
  library.consolidate_library
  settings.last_updated = Time.now
  exit(0)
end

if args.include?("--add")
  add_path = args[args.index("--add")+1]
  if (File.exists?(add_path) and File.directory?(add_path))
    library.add_songs_from(add_path, (args.include?("--move") ? "mv" : "cp"))
  else
    puts "Invalid path: #{add_path}"
  end
  exit(0)
end

if args.include?("--rebuild")
  library.build_index
end

if args.include?("--search")
  filters = args - args.select{|a| a.start_with?("--") }
  library.search(filters)
  exit(0)
end

#play the library
filters = args.reject{|a| a.start_with?("--") }
library.play(filters)
