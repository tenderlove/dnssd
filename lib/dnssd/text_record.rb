require 'delegate'

##
# DNSSD::TextRecord is a Hash delegate that can encode its contents for DNSSD.

class DNSSD::TextRecord < DelegateClass(Hash)

  ##
  # Creates a new TextRecord decoding an encoded +text_record+ if given or
  # from a given Hash.
  #
  #   DNSSD::TextRecord.new "\003k=v"
  #
  # or
  #
  #   DNSSD::TextRecord.new 'k' => 'v'

  def initialize(text_record = nil)
    super case text_record
          when Hash then
            text_record.dup
          when String then
            decode(text_record.dup)
          else
            Hash.new
          end
  end

  ##
  # Decodes +text_record+ and returns a Hash

  def decode(text_record)
    record = {}

    tr = text_record.unpack 'C*'

    until tr.empty? do
      size  = tr.shift

      next if size.zero?

      raise ArgumentError, 'ran out of data in text record' if tr.length < size

      entry = tr.shift(size).pack('C*')

      raise ArgumentError, 'key not found' unless entry =~ /^[^=]/

      key, value = entry.split '=', 2

      next unless key

      record[key] = value
    end

    record
  end

  ##
  # Encodes this TextRecord.  A key value pair must be less than 255 bytes in
  # length.  Keys longer than 14 bytes may not be compatible with all
  # clients.

  def encode
    sort.map do |key, value|
      key = key.to_s

      raise DNSSD::Error, "empty key" if key.empty?
      raise DNSSD::Error, "key '#{key}' contains =" if key =~ /=/

      record = value ? [key, value.to_s].join('=') : key

      raise DNSSD::Error, "key value pair at '#{key}' too large to encode" if
        record.length > 255

      "#{record.length.chr}#{record}"
    end.join ''
  end

end

