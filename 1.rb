require 'logger'
require 'timeout'
require 'socket'

module Connection
  def self.do(str)
    str.each_line{ |line|
      agent.puts(str)
    }
    read
  end

  def self.read
    result = ""
    begin
      timeout(0.1) do
        loop do
          result += agent.gets || ''
        end
      end
    rescue Timeout::Error
    end
    result
  end

  def self.agent
    unless @agent
      @agent = TCPSocket.new("localhost", 4242)
    end
    @agent
  end

  def logger
    @logger ||= Logger.new
  end
end

puts Connection.do <<EOF
events = [];
document.onclick = function(e) {
  events.push(e.target);
}
events;
EOF

begin
  loop do
    print Connection.do "events.pop()"
    sleep 1
  end
rescue Interrupt
  Connection.do "exit"
end
