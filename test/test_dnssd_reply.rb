require 'minitest/autorun'
require 'dnssd'

class TestDNSSDReply < MiniTest::Unit::TestCase

  def setup
    @reply = DNSSD::Reply.new
    @fullname = "Eric\\032Hodel._http._tcp.local."
  end

  def test_class_from_service
    reply = DNSSD::Reply.from_service :service, 4

    assert_equal :service, reply.service
    assert_equal DNSSD::Flags::Default, reply.flags
  end

  def test_connect_tcp
    port = Socket.getservbyname 'blackjack'
    @reply.set_fullname 'blackjack._http._tcp.local.'
    @reply.instance_variable_set :@port, port
    @reply.instance_variable_set :@target, 'localhost'

    server = TCPServer.new 'localhost', port

    socket = @reply.connect

    assert_instance_of TCPSocket, socket
    assert_equal port,        socket.peeraddr[1]
    assert_equal 'localhost', socket.peeraddr[2]
  ensure
    socket.close
    server.close
  end

  def test_connect_tcp_no_port_target
    skip "sync calls suck"
    return
    port = Socket.getservbyname 'blackjack'
    server = TCPServer.new nil, port
    Thread.start do server.accept end

    DNSSD.announce server, 'blackjack'

    @reply.set_fullname 'blackjack._http._tcp.local.'

    socket = @reply.connect

    assert_instance_of TCPSocket, socket
    assert_equal port,        socket.peeraddr[1]
    assert_equal 'localhost', socket.peeraddr[2]
  ensure
    socket.close if socket
    server.close if server
  end

  def test_connect_udp
    port = Socket.getservbyname 'blackjack'
    @reply.set_fullname 'blackjack._http._udp.local.'
    @reply.instance_variable_set :@port, port
    @reply.instance_variable_set :@target, 'localhost'

    server = UDPSocket.new
    server.bind 'localhost', port

    socket = @reply.connect

    assert_instance_of UDPSocket, socket
    assert_equal port,        socket.peeraddr[1]
    assert_equal 'localhost', socket.peeraddr[2]
  ensure
    socket.close
    server.close
  end

  def test_fullname
    @reply.set_fullname @fullname

    assert_equal "Eric\\032Hodel._http._tcp.local.", @reply.fullname

    @reply.instance_variable_set :@name, 'Dr. Pepper'

    assert_equal "Dr\\.\\032Pepper._http._tcp.local.", @reply.fullname
  end

  def test_inspect
    flags = DNSSD::Flags.new
    @reply.instance_variable_set :@fullname,  'blah'
    @reply.instance_variable_set :@name,      'drbrain@pincer-tip'
    @reply.instance_variable_set :@interface, 'en2'
    @reply.instance_variable_set :@domain,    'local'
    @reply.instance_variable_set :@flags,     flags
    @reply.instance_variable_set :@type,      '_presence._tcp'

    expected = "#<DNSSD::Reply:0x#{@reply.object_id.to_s 16} \"drbrain@pincer-tip\" type: _presence._tcp domain: local interface: en2 flags: #{flags}>"
    assert_equal expected, @reply.inspect
  end

  def test_protocol
    @reply.set_fullname @fullname

    assert_equal 'tcp', @reply.protocol
  end

  def test_service_name
    @reply.set_fullname @fullname

    assert_equal 'http', @reply.service_name
  end

  def test_set_fullname
    @reply.set_fullname @fullname

    assert_equal 'Eric Hodel', @reply.name
    assert_equal '_http._tcp', @reply.type
    assert_equal 'local.', @reply.domain

    @reply.set_fullname "Dr\\.\\032Pepper._http._tcp.local."

    assert_equal 'Dr. Pepper', @reply.name
    assert_equal '_http._tcp', @reply.type
    assert_equal 'local.', @reply.domain
  end

  def test_set_names
    @reply.set_names "Dr\\.\032Pepper", '_http._tcp', 'local.'

    assert_equal "Dr.\032Pepper", @reply.name
    assert_equal '_http._tcp', @reply.type
    assert_equal 'local.', @reply.domain
  end

end

