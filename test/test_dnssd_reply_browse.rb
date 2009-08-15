require 'minitest/autorun'
require 'dnssd'

class TestDNSSDReplyBrowse < MiniTest::Unit::TestCase

  def setup
    @reply = DNSSD::Reply::Browse.new nil, 0, 0, "blackjack\\032no\\032port",
                                      '_blackjack._tcp', 'local'
  end

  def test_connect
    port = Socket.getservbyname 'blackjack'
    server = TCPServer.new nil, port
    Thread.start do server.accept end

    DNSSD.announce server, 'blackjack no port'

    socket = @reply.connect

    assert_instance_of TCPSocket, socket
    assert_equal port, socket.peeraddr[1]
  ensure
    socket.close if socket
    server.close if server
  end

end

