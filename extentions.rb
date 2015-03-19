require "readline"

class String
  def blank?
    self.nil? or self.strip.length == 0
  end
  def present?
    !blank?
  end
  def sanitize
    strip.gsub("/", "-").gsub(/[^a-z0-9\s\'\.\[\]\#\-\(\)\_&,!=]/i, "_")
  end

  #http://bogojoker.com/readline/
  # Smarter Readline to prevent empty and dups
  #   1. Read a line and append to history
  #   2. Quick Break on nil
  #   3. Remove from history if empty or dup
  #
  def self.read(prompt = "> ")
    line = Readline.readline(prompt, true)
    return "" if line.nil?
    if line =~ /^\s*$/ or Readline::HISTORY.to_a[-2] == line
      Readline::HISTORY.pop
    end
    line
  end

end

class NilClass
  def blank?
    return true
  end
  def present?
    return false
  end
end


class Array
  def rand
    self[super(self.count)]
  end
  def blank?
    self.count == 0
  end
  def present?
    !blank?
  end

  def in_groups_of(number, fill_with = nil)
    if fill_with == false
      collection = self
    else
      # size % number gives how many extra we have;
      # subtracting from number gives how many to add;
      # modulo number ensures we don't add group of just fill.
      padding = (number - size % number) % number
      collection = dup.concat([fill_with] * padding)
    end

    if block_given?
      collection.each_slice(number) { |slice| yield(slice) }
    else
      groups = []
      collection.each_slice(number) { |group| groups << group }
      groups
    end
  end

end

class Time
  def elapsed(options={})
    default_options = {
      round_digits: 2
    }
    options = default_options.merge(options)
    elapsed = Time.now - self
    elapsed.round(options[:round_digits])
  end
end
