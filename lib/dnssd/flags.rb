class DNSSD::Flags

  def inspect # :nodoc:
    flags = to_a.sort.join ', '
    flags[0, 0] = ' ' unless flags.empty?
    "#<#{self.class}#{flags}>"
  end

end
