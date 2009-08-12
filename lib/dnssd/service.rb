class DNSSD::Service

  ##
  # Access the services underlying thread.  Returns nil if the service is
  # synchronous.

  attr_reader :thread
  
  def inspect # :nodoc:
    stopped = stopped? ? 'stopped' : 'running'
    "#<%s:0x%x %s>" % [self.class, object_id, stopped]
  end

end

