require 'pp'
require 'logger'
require 'timeout'
require 'socket'
require 'json'

class Connection
  def initialize(host = 'localhost', port = 4242)
    @host = host
    @port = port
    logger.debug("instance created")
  end

  def do(str)
    puts(str)
    read
  rescue Errno::EPIPE, Errno::ECONNRESET => e
    logger.error("connection seems broken")
    @agent = nil
    read
    retry
  end

  def puts(str)
    agent.puts(str)
    logger.debug("send: #{str}")
  end

  def read
    result = ""
    begin
      timeout(0.1) do
        loop do
          result += agent.gets || ''
        end
      end
    rescue Timeout::Error
    end
    logger.debug("receive: #{result}")
    result
  end

  def agent
    unless @agent
      logger.info("connect to #{@host}:#{@port}")
      @agent = TCPSocket.new(@host, @port)
    end
    @agent
  end

  def logger
    @logger ||= Logger.new(STDOUT)
  end
end

c = Connection.new
c.logger.level = Logger::FATAL
c.do <<EOF
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
if (!events) events = [];
document.addEventListener("click", recordevents, true);
EOF

begin
  loop do
    event = c.do "events.pop()"
    if event.size > 0
      puts event.gsub(/\\u(\w{4})/){ |s| [$1.to_i(16)].pack('U')}
    end
  end
rescue Interrupt
  c.do "exit"
end
