require 'socket'

port = (ARGV[0] || 8080).to_i

Socket.tcp_server_loop(port) do |client, addr_info|
  STDOUT.print '.'; STDOUT.flush
  Thread.new do
    begin
      client.puts "Hello !"
      client.puts "Time is #{Time.now}"
    rescue
      # Ignore
    ensure
      client.close
    end
  end
end
