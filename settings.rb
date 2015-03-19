class Settings
  SETTINGS_FILE = "files/settings.txt"

  def initialize
    readfile
  end

  protected
  def readfile
    @settings = File.read(SETTINGS_FILE).split("\n").inject({}) do |s, i|
      tokens = i.split(":")
      s[tokens[0].strip] = if tokens[1] == "Time"
        Time.at(tokens[2].strip.to_i)
      elsif tokens[1] == "FalseClass"
        false
      elsif tokens[1] == "TrueClass"
        true
      else
        tokens[2].strip
      end
      s
    end
  end

  def write_file
    File.open(SETTINGS_FILE, 'w') do |f|
      @settings.each do |k, v|
        value = if v.class == Time
          v.to_i
        else
          v
        end
        f.puts "#{k}:#{v.class}:#{value}"
      end
    end
  end

  def method_missing(*args)
    key = args.first.to_s
    if key.end_with?("=")
      @settings[key[0..-2]] = args[1]
      write_file
    else
      return @settings[key]
    end
  end


end