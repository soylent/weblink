require 'csv'
require 'time'

class Relay < EventMachine::Connection
  def initialize(tag, xff = nil)
    super
    pause
    @tag = tag
    @xff = xff
    @remote_port, @remote_ip = unpack_sockaddr_in(get_peername)
    @websocket = nil
    @ws_remote_ip = nil
    @ws_remote_port = nil
  end

  def start(websocket)
    @websocket = websocket
    @websocket.onbinary do |msg|
      log('recv', msg.bytesize)
      send_data(msg)
    end
    @websocket.onerror { |err| log('ws/error', err) }
    @websocket.onclose { close_connection_after_writing }
    @ws_remote_port, @ws_remote_ip = unpack_sockaddr_in(websocket.get_peername)
    resume
  end

  def receive_data(data)
    log('sent', data.bytesize)
    @websocket.send_binary(data)
  end

  def unbind
    log('close')
    # Status code 1000 indicates a normal closure.
    @websocket&.close(1000) if @websocket&.state == :connected
  end

  private

  def log(event, comment = nil)
    row = [
      Time.now.iso8601(3),
      @tag,
      @xff,
      @remote_ip,
      @remote_port&.to_s,
      @ws_remote_ip,
      @ws_remote_port&.to_s,
      event,
      comment&.to_s,
    ]

    puts CSV.generate_line(row, col_sep: ' ', write_nil_value: '-')
  end

  def unpack_sockaddr_in(sock)
    Socket.unpack_sockaddr_in(sock) if sock
  rescue ArgumentError
  end
end
