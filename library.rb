require "fileutils"
require "timeout"

require "./extentions"
require "./mp3"
require "./android"

class Library

  INDEX_FILENAME = "files/index.txt"

  def initialize(settings)
    @settings = settings
    @basepath = @settings.basepath

    raise "Invalid Path #{@basepath}" if !File.exists?(@basepath) and !File.directory?(@basepath)

    if @settings.rebuild
      build_index
      @settings.rebuild = false
    end
    @broadcast = nil
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
    raise "Invalid file operation: should be either 'cp' or 'mv'" unless %w(cp mv).include?(file_operation)
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
    s = Time.now
    filepaths = Dir["#{@basepath}/**/*.mp3"].entries.select{|a| File.file?(a) }
    File.open(INDEX_FILENAME, 'w'){|f| f.puts filepaths.join("|") }
    puts "done rebuilding .. (#{s.elapsed}s)"
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
          tokens = filter.split(/\s+/).map(&:downcase)
          files.each do |file|
            if tokens.all?{|t| file.downcase.include?(t) }
              filtered_songs << file 
            end
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
    loop do
      begin
        cmd = String.read("cmd> ")
        if /^(h|help|\?)$/i =~ cmd
          puts ""
          puts "commands:"
          puts "help (also h, ?): print this help message"
          puts "info (also i): print mp3 info on this song"
          puts "remove (also r): remove this file"
          puts "mobile (also m): move this file to available android device (via adb command)"
          puts "next (also n): play the next file"
          puts "exit (also quit): quit the program"
        elsif /^(info|i)$/i =~ cmd
          Mp3.new(path).inspect
          
        elsif /^(remove|r)$/i =~ cmd
          puts "removing: #{path}"
          FileUtils.rm_f(path)
          @settings.rebuild = true
        elsif /^(mobile|m)$/i =~ cmd
          puts "copying to phone"
          Android.cp(path, path.gsub("#{@basepath}/", ""))
        elsif /^(next|n)$/i =~ cmd
          @broadcast = "next"
        elsif /^(exit|quit)$/i =~ cmd
          @broadcast = "exit"
          break
        else
          puts "invalid command: #{cmd}\nuse 'help' to see available commands..."
        end


      rescue RuntimeError => e
        break
      end
    end

  end

  def search(filters)
    if filters.blank?
      puts "nothing to search"
      return
    end
    search_results = get_files(filters)
    if search_results.blank?
      puts "no results"
      return
    end

    all_songs = get_files([])
    puts @basepath
    search_results.first(100).each_with_index do |file, i|
      puts "#{all_songs.index(file)}: #{file.gsub(@basepath, "")}"
    end
    
  end

  def play_file(path)
    puts "#{path}\n"
    cmd = "vlc --quiet --play-and-exit --qt-start-minimized '#{path.gsub(/\'/, "\\'")}' > /dev/null 2>&1"
    `#{cmd}`
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
        vlc = Thread.new{ play_file(path) }
        user_commands = Thread.new{ sleep(1); process_input_during_play(path) }

        while(vlc.status) do
          sleep(1)
          if @broadcast == "exit" or @broadcast == "next"
            `pkill vlc`
            @broadcast = nil if @broadcast == "next"
          end
        end
        user_commands.raise("stfu")
        puts "\n\n"

        break if @broadcast == "exit"
      end
    rescue Interrupt => i
      puts "\ninterrupted by user..."
    end
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

