require 'socket'
require 'thread'
require 'optparse'

Thread.abort_on_exception = true

options = {
  :concurrency => 1,
  :output_interval => 1
}
OptionParser.new do |opts|
  opts.banner = "Usage: ruby client.rb [options] [server[:port]]"

  opts.on("-P", "--parallel n", "Number of parallel client connections (default: 1)") do |n|
    options[:concurrency] = n.to_i
  end

  opts.on("-i", "--interval n", "Output connection rate every n seconds (default: 1)") do |n|
    options[:output_interval] = n.to_i
  end

  opts.on("-h", "--help", "Print usage") do
    puts opts
    exit
  end
end.parse!

server_host, server_port = (ARGV[0] || '').split(':')
server_port = (server_port || 8080).to_i

connection_rate = (ARGV[1] || 100).to_i

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

timers = options[:concurrency].times.map {|i| Timer.new(connection_rate, "connection source #{i}") }
output_timer = Timer.new(1/options[:output_interval].to_f, "output")

Thread.new do
  output_timer.each_tick do
    puts "#{Time.now} - Connections/s = #{connections / options[:output_interval]}, Total connections = #{total_cxns}"
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
