require 'helper'

class TestDNSSDReplyResolve < DNSSD::Test

  def setup
    @port = stub Socket, :getservbyname, 1025 do
      Socket.getservbyname 'blackjack'
    end
    @interface = DNSSD::InterfaceAny
    super
  end

  def test_connect_tcp
    fullname = "blackjack\\032no\\032port._blackjack._tcp.local."
    reply = DNSSD::Reply::Resolve.new nil, 0, @interface, fullname,
                                      'localhost', @port, nil

    server = TCPServer.new nil, @port

    socket = reply.connect

    assert_instance_of TCPSocket, socket
    assert_equal @port,       socket.peeraddr[1]

    if socket.method(:peeraddr).arity.zero? then
      assert_equal 'localhost', socket.peeraddr[2]
    else
      assert_equal 'localhost', socket.peeraddr(true)[2]
    end
  ensure
    socket.close if socket
    server.close if server
  end

  def test_connect_udp
    fullname = "blackjack\\032no\\032port._blackjack._udp.local."
    reply = DNSSD::Reply::Resolve.new nil, 0, @interface, fullname,
                                      'localhost', @port, nil

    server = UDPSocket.new
    server.bind 'localhost', @port

    socket = reply.connect

    assert_instance_of UDPSocket, socket
    assert_equal @port,       socket.peeraddr[1]

    if socket.method(:peeraddr).arity.zero? then
      assert_equal 'localhost', socket.peeraddr[2]
    else
      assert_equal 'localhost', socket.peeraddr(true)[2]
    end
  ensure
    socket.close if socket
    server.close if server
  end

end

