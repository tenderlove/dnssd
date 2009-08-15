##
# DNSSD::TextRecord is a Hash wrapper that can encode its contents for DNSSD.

class DNSSD::TextRecord

  ##
  # Creates a new TextRecord, decoding an encoded +text_record+ if given.

  def initialize(text_record = nil)
    @records = {}

    return unless text_record

    text_record = text_record.dup

    until text_record.empty? do
      size = text_record.slice! 0
      next if size.zero?

      raise ArgumentError, 'ran out of data in text record' if
        text_record.length < size

      entry = text_record.slice! 0, size

      raise ArgumentError, 'key not found' unless entry =~ /^[^=]/

      key, value = entry.split '=', 2

      next unless key

      @records[key] = value
    end
  end

  def [](key)
    @records[key]
  end

  def []=(key, value)
    @records[key] = value
  end

  ##
  # Is this TextRecord empty?

  def empty?
    @records.empty?
  end

  ##
  # Encodes this TextRecord.  A key value pair must be less than 255 bytes in
  # length.  Keys longer than 14 bytes may not be compatible with all
  # clients.

  def encode
    @records.sort.map do |key, value|
      key = key.to_s

      raise DNSSD::Error, "empty key" if key.empty?
      raise DNSSD::Error, "key '#{key}' contains =" if key =~ /=/

      record = value ? [key, value.to_s].join('=') : key

      raise DNSSD::Error, "key value pair at '#{key}' too large to encode" if
        record.length > 255

      "#{record.length.chr}#{record}"
    end.join ''
  end

  def inspect # :nodoc:
    @records.inspect
  end

  def to_hash
    @records.dup
  end

  def to_s # :nodoc:
    @records.to_s
  end

end

