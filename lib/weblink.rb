require 'em-websocket'
require 'eventmachine'
require 'socket'
require 'tempfile'
require 'relay'

class Weblink
  def initialize(opts)
    @opts = opts
    @proxxxy_socket = Tempfile.new('weblink')
    @websockets = EventMachine::Queue.new
  end

  def start
    trap(:EXIT) { Process.waitall }

    if @opts[:client]
      public = File.expand_path('../public', __dir__)
      spawn('ruby', '-run', '-ehttpd', '--', public, err: IO::NULL)

      ip = Socket.getifaddrs.find { |ifa| ifa.addr.ipv4_private? }
      puts "Open http://#{ip.addr.ip_address}:8080/ on your other device." if ip
    end

    if @opts[:server]
      begin
        spawn('proxxxy', "socks5://#{@proxxxy_socket.path}")
      rescue Errno::ENOENT
        abort('Please install proxxxy v2 to run weblink server')
      end
    end

    EventMachine::WebSocket.start(@opts) do |ws|
      ws.onopen do |handshake|
        case handshake.path
        when '/control'
          start_client(ws)
          puts 'Ready'
        when '/client'
          @websockets.push(ws)
        when '/server'
          proxy(ws, handshake)
        else
          warn("Unexpected request: #{handshake.path.inspect}")
        end
      end
    end
  end

  private

  def start_client(control_ws, min_ws_num: 3)
    host, port = @opts.values_at(:proxy_host, :proxy_port)
    sig = EventMachine.start_server(host, port, Relay, 'client') do |rel|
      # Dogpile effect
      control_ws.send_text('more_ws') if @websockets.size < min_ws_num
      @websockets.pop { |ws| rel.start(ws) }
    end
    control_ws.onclose { EventMachine.stop_server(sig) }
  end

  def proxy(ws, handshake)
    unless @opts[:server]
      warn 'weblink server is disabled'
      return
    end
    xff = handshake.headers_downcased['x-forwarded-for']
    with_retry(3) do
      EventMachine.connect(@proxxxy_socket.path, Relay, 'server', xff) do |rel|
        rel.start(ws)
      end
    end
  end

  def with_retry(timeout, wait: 0.1)
    elapsed = 0
    begin
      yield
    rescue RuntimeError
      if elapsed < timeout
        elapsed += sleep(wait)
        retry
      end
    end
  end
end
