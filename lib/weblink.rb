require 'em-websocket'
require 'eventmachine'
require 'socket'
require 'tempfile'
require 'relay'

class Weblink
  def initialize(opts)
    @opts = opts
    @https = Tempfile.new('weblink')
    @socks5 = Tempfile.new('weblink')
    @websockets = EventMachine::Queue.new
  end

  def start
    trap(:EXIT) { Process.waitall }

    if @opts[:client]
      ip = Socket.getifaddrs.find { |ifa| ifa.addr&.ipv4_private? }
      if ip
        public = File.expand_path('../public', __dir__)
        spawn('ruby', '-run', '-ehttpd', '--', public, err: IO::NULL)
        puts "[~] Open http://#{ip.addr.ip_address}:8080/ on your other device."
      else
        abort(
          "[-] Could not find an interface to listen on. " \
          "Make sure that you are connected to your device."
        )
      end
    end

    if @opts[:server]
      begin
        spawn('proxxxy', "https://#{@https.path}", "socks5://#{@socks5.path}")
      rescue Errno::ENOENT
        abort('[-] Install proxxy v2 to run weblink server.')
      end
    end

    EventMachine::WebSocket.start(@opts) do |ws|
      ws.onopen do |handshake|
        case handshake.path
        when '/control'
          start_client(ws)
        when '/client'
          @websockets.push(ws)
        when '/proxy/socks5'
          proxy(ws, handshake, @socks5.path)
        when '/proxy/https'
          proxy(ws, handshake, @https.path)
        else
          warn("[!] Unexpected request: #{handshake.path.inspect}")
        end
      end
    end
  end

  private

  def start_client(control_ws, min_ws_num: 3)
    type, host, port = @opts.values_at(:proxy_type, :proxy_host, :proxy_port)
    sig = EventMachine.start_server(host, port, Relay, 'client') do |relay|
      # Dogpile effect
      control_ws.send_text(type) if @websockets.size < min_ws_num
      @websockets.pop { |ws| relay.start(ws) }
    end
    control_ws.onclose { EventMachine.stop_server(sig) }
    puts "[+] Ready: #{type} proxy is listening on #{host}:#{port}."
  end

  def proxy(ws, handshake, socket, ping_interval: 45)
    unless @opts[:server]
      warn '[!] weblink server is disabled.'
      return
    end
    xff = handshake.headers_downcased['x-forwarded-for']
    with_retry do
      EventMachine.connect(socket, Relay, 'server', xff) do |relay|
        relay.start(ws)
        # TODO: Instead of creating a timer per websocket, it might be more
        # efficient to create a single timer and iterate over all open
        # websockets.
        timer = EventMachine.add_periodic_timer(ping_interval) { ws.ping }
        ws.onclose { timer.cancel }
      end
    end
  end

  def with_retry(timeout: 3, wait: 0.1)
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
