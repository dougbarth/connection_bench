require 'socket'

server_host, server_port = ARGV[0].split(':')
server_port = (server_port || 8080).to_i
connection_rate = (ARGV[1] || 100).to_i

output_interval = 1
next_output_time = Time.now + output_interval

total_cxns = 0
connections = 0

class Timer
  def initialize(frequency, name = nil)
    @frequency = frequency
    @name = name

    @keep_going = true

    @tick_interval = 1 / @frequency.to_f

    @next_fire = Time.now
    @fired_up_to = Time.now
  end

  def each_tick
    while @keep_going
      now = Time.now
      missed = ((now - @fired_up_to) * @frequency).floor

      if missed > 0
        missed.times do
          yield
        end

        @fired_up_to = @fired_up_to + missed * @tick_interval
      end

      sleep(0.001)
    end
  end

  def stop
    @keep_going = false
  end
end

timer = Timer.new(connection_rate, "connections")
output_timer = Timer.new(1/output_interval.to_f, "output")

trap("INT") do
  timer.stop
  output_timer.stop
end

Thread.new do
  output_timer.each_tick do
    puts "#{Time.now} - Connections/s = #{connections / output_interval}, Total connections = #{total_cxns}"
    connections = 0
  end
end

timer.each_tick do
  s = TCPSocket.new(server_host, server_port)

  while line = s.gets # Read lines from socket
    #puts line         # and print them
  end

  s.close             # close socket when done

  total_cxns += 1
  connections += 1
end

