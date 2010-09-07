require 'minitest/autorun'
require 'dnssd'

class TestDNSSDReplyBrowse < MiniTest::Unit::TestCase

  def test_connect
    reply = DNSSD::Reply::Browse.new nil, 0, 0, 'blackjack no port',
                                     '_blackjack._tcp', 'local'

    port = Socket.getservbyname 'blackjack'
    server = TCPServer.new nil, port
    Thread.start do server.accept end

    DNSSD.announce server, 'blackjack no port'

    socket = reply.connect

    assert_instance_of TCPSocket, socket
    assert_equal port, socket.peeraddr[1]
  ensure
    socket.close if socket
    server.close if server
  end

  def test_connect_encoding
    skip 'Encoding not defined' unless Object.const_defined? :Encoding

    reply = DNSSD::Reply::Browse.new nil, 0, 0, "\u00E9",
                                     '_blackjack._tcp', 'local'


    port = Socket.getservbyname 'blackjack'
    server = TCPServer.new nil, port
    Thread.start do server.accept end

    name = "\u00E9"
    name.encode! Encoding::ISO_8859_1

    DNSSD.announce server, name

    socket = reply.connect

    assert_instance_of TCPSocket, socket
    assert_equal port, socket.peeraddr[1]
  ensure
    socket.close if socket
    server.close if server
  end

end

