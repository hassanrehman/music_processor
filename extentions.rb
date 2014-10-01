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
end
