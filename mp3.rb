require "mp3info"

class Mp3
  attr_reader :filepath, :artist, :album, :title, :tracknum, :info

  def initialize(filepath)
    @filepath = filepath
    begin
      @info = {}
      Mp3Info.open(filepath) do |mp3|
        # puts "path: #{filepath}"
        # puts "Artist: #{mp3.tag.artist}"
        # puts "Title: #{mp3.tag.title}"
        # puts "Album: #{mp3.tag.album}"
        # puts "Track Num: #{mp3.tag.tracknum}"

        # puts "TAG 2 INFO"
        %w(TIT1 TIT2 TIT3 TALB TOAL TOPE WOAR TPE1 TPE2).each do |key|
          #puts "#{key} : #{mp3.tag2[key]}"
          @info[key] = mp3.tag2[key]
        end
        @artist = (extract_artist(mp3) || "Unknown Artist").sanitize
        @title = mp3.tag.title.present? ? mp3.tag.title.sanitize.strip[0...36] : "Unknown Title"
        @album = mp3.tag.album.present? ? mp3.tag.album.sanitize.strip[0...40].strip.sanitize : "Unknown Album"
        @tracknum = if !mp3.tag.tracknum.nil?
          mp3.tag.tracknum < 10 ? "0#{mp3.tag.tracknum}" : mp3.tag.tracknum
        end
      end
    rescue StandardError => e
      puts "ERROR while processing: #{filepath}"
      raise e
    end
  end

  def filepath(basepath=nil)
    tracknum_str = @tracknum.nil? ? "" : "#{@tracknum} "
    path = "#{@artist}/#{@album}/#{tracknum_str}#{@title}.mp3"
    return (basepath.blank? ? path : "#{basepath}/#{path}" )
  end

  def inspect
    puts "Path: #{@filepath}"
    puts "Artist: #{@artist}"
    puts "Album: #{@album}"
    puts "Title: #{@title}"
    puts "Track No.: #{@tracknum}"
  end


  private
  def purify()
  end
  def extract_artist(mp3)
    tpe2 = mp3.tag2["TPE2"]
    tpe2 = tpe2.first if tpe2.is_a?(Array)

    return tpe2 if tpe2.present?

    tpe1 = mp3.tag2["TPE1"]
    tpe1 = tpe1.first if tpe1.is_a?(Array)

    return tpe1 if tpe1.present?

    return mp3.tag.artist if mp3.tag.artist.present?

    return nil
  end

end