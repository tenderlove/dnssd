##
# Flags used in DNSSD Ruby API.

class DNSSD::Flags

  constants.each do |name|
    next unless name =~ /[a-z]/
    attr = name.to_s.gsub(/([a-z])([A-Z])/, '\1_\2').downcase

    flag = const_get name

    define_method "#{attr}=" do |bool|
      if bool then
        set_flag flag
      else
        clear_flag flag
      end
    end

    define_method "#{attr}?" do
      self & flag == flag
    end
  end

  ##
  # Bitfield with all valid flags set

  ALL_FLAGS = FLAGS.values.inject { |flag, all| flag | all }

  ##
  # Returns a new set of flags

  def initialize(*flags)
    @flags = flags.inject 0 do |flag, acc| flag | acc end

    verify
  end

  ##
  # Returns the intersection of flags in +self+ and +flags+.

  def &(flags)
    self.class.new(to_i & flags.to_i)
  end

  ##
  # +self+ is equal if +other+ has the same flags

  def ==(other)
    to_i == other.to_i
  end

  ##
  # Clears +flag+

  def clear_flag(flag)
    @flags &= ~flag

    verify
  end

  def inspect # :nodoc:
    flags = to_a.sort.join ', '
    flags[0, 0] = ' ' unless flags.empty?
    "#<#{self.class}#{flags}>"
  end

  ##
  # Sets +flag+

  def set_flag(flag)
    @flags |= flag

    verify
  end

  ##
  # Returns an Array of flag names

  def to_a
    FLAGS.map do |name, value|
      (@flags & value == value) ? name : nil
    end.compact
  end

  ##
  # Flags as a bitfield

  def to_i
    @flags
  end

  ##
  # Trims the flag list down to valid flags

  def verify
    @flags &= ALL_FLAGS

    self
  end

  ##
  # Returns the union of flags in +self+ and +flags+

  def |(flags)
    self.class.new(to_i | flags.to_i)
  end

  ##
  # Returns the complement of the flags in +self+

  def ~
    self.class.new ~to_i
  end

end
