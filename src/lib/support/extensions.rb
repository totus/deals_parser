# monkey-patching Hash class to create an object out of hash
class Hash
  def to_obj
    local_keys = keys
    local_self = self
    Class.new do
      local_keys.each do |attr|
        define_method(attr.to_sym) { local_self.fetch(attr) }
      end
    end.new
  end
end

# Monkey-patching Time class to add "between" syntactic sugar
class Time
  def between?(start_time, end_time)
    self > start_time && self < end_time
  end
end
