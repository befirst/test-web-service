# ab -n 10000 -c 100 -p ./section_one/ostechnix.txt localhost:1234/
# head -c 100000 /dev/urandom > section_one/ostechnix_big.txt

require 'socket'
require './lib/response'
require './lib/request'
MAX_EOL = 2
ROOT_DIR = 'public'.freeze

socket = TCPServer.new(ENV['HOST'], ENV['PORT'])

def handle_request(request_text, client)
  request = Request.new(request_text)
  puts("#{client.peeraddr[3]} #{request.path}")
  file, content_type = get_requested_data(request)

  response = Response.new(code: 200, data: file, content_type: content_type)
  response.send(client)

  client.shutdown
end

def get_requested_data(request)
  file_path = ROOT_DIR + request.path
  file = File.read(file_path)
  ext = File.extname(file_path).split('.').last
  content_type_mapping = {
    'html' => 'text/html',
    'txt' => 'text/plain',
    'png' => 'image/png',
    'jpg' => 'image/jpeg',
  }

  content_type = content_type_mapping.fetch(ext, 'application/octet-stream')

  [file, content_type]
end

def handle_connection(client)
  puts("Getting new client #{client}")
  request_text = ''
  eol_count = 0

  loop do
    buf = client.recv(1)
    puts "#{client} #{buf}"
    request_text += buf

    eol_count += 1 if buf == "\n"

    if eol_count == MAX_EOL
      handle_request(request_text, client)
      break
    end
  end
rescue Errno::ENOENT
  respond_with_error(client, 404, 'The requested resource not found')
rescue Errno::EACCES
  respond_with_error(client, 403, "You don't have permissions to access this resource")
rescue Ecxeption => e
  puts("Error: #{e}")
  respond_with_error(client, 500, 'Internal Server Error')
end

def respond_with_error(client, code, message)
  response = Response.new(code: code, data: message)
  response.send(client)

  client.close
end

puts("Listening on #{ENV['HOST']}:#{ENV['PORT']}. Press CTRL+C to cancel.")

loop do
  Thread.start(socket.accept) do |client|
    handle_connection(client)
  end
end
