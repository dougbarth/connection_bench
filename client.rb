require 'socket'
require 'thread'

Thread.abort_on_exception = true

server_host, server_port = (ARGV[0] || '').split(':')
server_port = (server_port || 8080).to_i

connection_rate = (ARGV[1] || 100).to_i
concurrency = (ARGV[2] || 1).to_i

output_interval = 1
next_output_time = Time.now + output_interval

total_cxns = 0
connections = 0

counter_mutex = Mutex.new

class Timer
  def initialize(frequency, name = nil)
    @frequency = frequency
    @name = name

    @keep_going = true

    @tick_interval = 1 / @frequency.to_f

    @fired_up_to = Time.now
  end

  def each_tick
    while @keep_going
      now = Time.now
      missed = ((now - @fired_up_to) * @frequency).floor

      missed.times do
        yield
        break unless @keep_going
      end

      @fired_up_to = @fired_up_to + missed * @tick_interval

      sleep(0.001)
    end
  end

  def stop
    @keep_going = false
  end
end

timers = concurrency.times.map {|i| Timer.new(connection_rate, "connection source #{i}") }
output_timer = Timer.new(1/output_interval.to_f, "output")

Thread.new do
  output_timer.each_tick do
    puts "#{Time.now} - Connections/s = #{connections / output_interval}, Total connections = #{total_cxns}"
    counter_mutex.synchronize do
      connections = 0
    end
  end
end

connection_threads = timers.map do |timer|
  Thread.new do
    timer.each_tick do
      s = TCPSocket.new(server_host, server_port)

      s.close             # close socket when done

      counter_mutex.synchronize do
        total_cxns += 1
        connections += 1
      end
    end
  end
end

already_tried_stopping = false
trap("INT") do
  if already_tried_stopping
    connection_threads.each {|t| t.raise("WHY WON'T YOU DIE?") }
  else
    timers.each(&:stop)
    output_timer.stop
    already_tried_stopping = true
  end
end

connection_threads.each {|t| t.join }
