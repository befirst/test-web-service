class Response
  attr_reader :code

  def initialize(code:, headers: [], data: '', content_type: 'application/json')
    @code = code
    @data = data
    @headers = headers
    @content_type = content_type
  end

  def headers
    "HTTP/1.1 #{@code}\r\n" +
      "Content-Type: #{@content_type}\r\n" +
      "Content-Length: #{@data.bytesize}\r\n" +
      @headers.join("\r\n") +
      "\r\n"
  end

  def body
    "#{@data}\r\n"
  end

  def send(client)
    puts("Respond with #{@code}")
    puts headers
    response = headers + body
    client.write(response)
  end
end
