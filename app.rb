require 'faye/websocket'
require 'redis'

App = lambda do |env|
  if Faye::WebSocket.websocket?(env)
    ws = Faye::WebSocket.new(env)

    Thread.new do
      Redis.new.subscribe 'chat' do |on|
        on.message do |channel, message|
          ws.send(message)
        end
      end
    end

    ws.on :message do |event|
      Redis.new.publish 'chat', event.data
      p "Got #{event.data}"
      # ws.send(event.data)
    end

    ws.on :close do |event|
      p [:close, event.code, event.reason]
      ws = nil
    end

    # Return async Rack response
    ws.rack_response

  else
    # Normal HTTP request
    [200, {'Content-Type' => 'text/plain'}, ['Hello']]
  end
end
