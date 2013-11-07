require 'socket'

port = (ARGV[0] || 8080).to_i

Socket.tcp_server_loop(port) do |client, addr_info|
  STDOUT.print '.'; STDOUT.flush
  Thread.new do
    client.close
  end
end
