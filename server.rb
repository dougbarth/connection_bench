require 'socket'

server = TCPServer.new(2000) # Server bind to port 2000
loop do
  begin
    client = server.accept    # Wait for a client to connect
    client.puts "Hello !"
    client.puts "Time is #{Time.now}"
  rescue
    # Ignore
  ensure
    client.close
  end
end
