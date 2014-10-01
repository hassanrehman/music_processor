require "fileutils"
require "timeout"

require "./extentions"
require "./mp3"
require "./android"

class Library

  INDEX_FILENAME = "files/index.txt"

  def initialize(basepath)
    raise "Invalid Path #{basepath}" if !File.exists?(basepath) and !File.directory?(basepath)
    @basepath = basepath
  end


  def get_destination_path(path)
    extname = File.extname(path)
    basename = File.basename(path, extname)

    new_basename = nil
    ["", *(1..10000).to_a].each do |i|
      new_basename = "#{basename.strip} #{i}".strip
      new_path = "#{File.dirname(path)}/#{new_basename}#{extname}"
      return new_path unless File.exists?(new_path)
    end
    return nil
  end

  def consolidate_library
    move_mp3_files(@basepath, @basepath, "mv")
    puts "completed .. verifying removing empty directories"
    ["#{@basepath}/**/", "#{@basepath}/*"].each do |glob|
      Dir[glob].each do |d|
        FileUtils.rm_rf(d) if Dir["#{d}/*"].count == 0
      end
    end
    build_index
  end

  def move_mp3_files(source_path, destination_path, file_operation="mv")
    raise "Invalid file operation: should be either :cp or :mv" unless %w(cp mv).include?(file_operation)
    paths = Dir["#{source_path}/**/*.mp3"]
    total = paths.count
    paths.each_with_index do |filepath, i|
      mp3 = Mp3.new(filepath)

      generated_filepath = mp3.filepath(destination_path)
      if generated_filepath != filepath
        begin
          new_path = get_destination_path(generated_filepath)
          FileUtils.mkdir_p(File.dirname(new_path))
          #puts "from: #{filepath}\n  to: #{new_path}\n"
          FileUtils.send(file_operation, filepath, new_path)
        rescue StandardError => e
          puts "ERROR: #{e.message}"
          puts "filepath: #{filepath}"
          puts "new_path: #{new_path}"
          raise e
        end
      end
      puts "#{i+1}/#{total}"
    end
    
  end

  def add_songs_from(source_path, file_operation="cp")
    move_mp3_files(source_path, @basepath, file_operation)
    build_index
  end

  def build_index
    puts "rebuilding library index on #{@basepath}"
    filepaths = []
    Dir["#{@basepath}/**/*.mp3"].entries.each do |f|
      if File.file?(f)
        filepaths << f
      end
    end
    File.open(INDEX_FILENAME, 'w'){|f| f.puts filepaths.join("|") }
    puts "done rebuilding.."
  end

  def get_files(filters=[])
    build_index unless File.exists?(INDEX_FILENAME)
    files = File.read(INDEX_FILENAME).split("|")
    if filters.length > 0
      selected_files = []
      filters.each do |filter|
        filtered_songs = []
        if filter.start_with?("id:")
          id = filter.split(":")[1]
          file = files[id.to_i]
          filtered_songs << file if file.present?
        else
          files.each do |file|
            filtered_songs << file if file.downcase.include?(filter.downcase)
          end
        end
        selected_files |= filtered_songs
      end
      files = selected_files
    end
    return files
  end

  #returns true if index needs to be rebuild for later
  def process_input_during_play(path)
    rebuild_when_done = false
    #we need to consume all inputs sent in by the user
    input_exists = true
    while input_exists do
      input = begin
        Timeout::timeout(1) do
          STDIN.gets.chomp
        end
      rescue Timeout::Error
        input_exists = false
        nil
      end
      if input.present?
        puts "processing input: #{input}"
        cmd = input.strip.downcase
        if cmd == "remove"
          puts "removing: #{path}"
          FileUtils.rm_f(path)
          rebuild_when_done = true
        elsif cmd == "to_phone"
          puts "copying: #{path} to phone"
          Android.cp(path, path.gsub("#{@basepath}/", ""))
        end
      end
    end
    return rebuild_when_done
  end

  def search(filters)
    if filters.blank?
      puts "no results"
      return
    end
    search_results = get_files(filters)
    if search_results.blank?
      puts "no results"
      return
    end

    all_songs = get_files([])
    search_results.first(100).each_with_index do |file, i|
      puts "#{all_songs.index(file)}: #{file.gsub(@basepath, "")}"
    end
    
  end

  def play_file(path)
    puts "#{path}\n"
    `vlc --quiet --play-and-exit --qt-start-minimized "#{path}"`
  end

  def play(filters=[])
    files = get_files(filters)
    total = files.length
    puts "TOTAL: #{total}"
    rebuild_when_done = false
    begin
      index = 0
      loop do 
        break if files.length == 0
        index += 1
        path = files.sample
        puts "#{index}/#{total}\n"
        files.delete(path)
        play_file(path)
        rebuild_when_done = true if process_input_during_play(path)
      end
    rescue Interrupt => i
      puts "\ninterrupted by user..."
    end
    build_index if rebuild_when_done
    puts "all done"
  end

  def self.copy_rand(from, to)
    100.times do
      artist = Dir["#{from}/*"].rand
      album = Dir["#{artist}/*"].rand
      song = Dir["#{album}/*"].rand
      begin
        if !artist.nil? and !album.nil? and !song.nil?
          real_to = File.dirname(song).gsub(from, to)

          puts song
          #puts File.dirname(song)
          puts real_to
          puts ""

          FileUtils.mkdir_p(real_to)
          FileUtils.cp(song, real_to)
        end
      rescue StandardError => e
        puts e.message
        puts artist
        puts album
        puts song
        raise e
      end
    end
  end

end

