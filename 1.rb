require 'pp'
require 'logger'
require 'timeout'
require 'socket'
require 'json'

module Connection
  def self.do(str)
    agent.puts(str)
    logger.debug("send: #{str}")
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
      logger.debug("connect")
      @agent = TCPSocket.new("localhost", 4242)
    end
    @agent
  end

  def self.logger
    @logger ||= Logger.new(STDOUT)
  end
end

puts Connection.do <<EOF
if (recordevents) {
  document.removeEventListener("click", recordevents, true);
}
var recordevents = function(e) {
  var o = {
    type: e.type
  };
  var t = {
    tagName: e.target.tagName,
    textContent: e.target.textContent,
    name: e.target.name,
    className: e.target.className,
    id: e.target.id,
    };
  o.target = t;
  events.push(uneval(o));
  };
events = [];
document.addEventListener("click", recordevents, true);
EOF

begin
  loop do
    event = Connection.do "events.pop()"
    if event.size > 0
        puts event
    end
    sleep 1
  end
rescue Interrupt
  Connection.do "exit"
end
