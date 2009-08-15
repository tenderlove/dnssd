class DNSSD::Record

  value_to_name = constants.map do |name|
    next if name.intern == :IN
    [const_get(name), name.to_s]
  end.compact.flatten

  ##
  # Maps record constant values to the constant name

  VALUE_TO_NAME = Hash[*value_to_name]

end

