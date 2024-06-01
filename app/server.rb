require "socket"

# You can use print statements as follows for debugging, they'll be visible when running tests.
print("Logs from your program will appear here!")

# Uncomment this to pass the first stage
#
server = TCPServer.new("localhost", 4221)

loop do
  client_socket, client_address = server.accept
  request = client_socket.gets
  verb, path, protocol = request.split(" ")
  headers = {}
  while line = client_socket.gets.split(' ', 2)
    break if line[0] == ""
    headers[line[0].chop] = line[1].strip
  end
  case path
  when "/"
    client_socket.puts "HTTP/1.1 200 OK\r\n\r\n"
  when /\/echo\/.*/
    content = path.split("/").last
    client_socket.puts "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length:#{content.length}\r\n\r\n#{content}"
  when /\/user-agent/
    agent = headers['User-Agent']
    client_socket.puts "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: #{agent.length}\r\n\r\n#{agent}"
  when /\/files/
    filename = path.split("/").last
    directory = ARGV[1]
    file_path = directory+filename
    if verb == 'GET'
      begin
        file = File.open("#{file_path}", "r").read
        client_socket.puts "HTTP/1.1 200 OK\r\nContent-Type: application/octet-stream\r\nContent-Length: #{file.length}\r\n\r\n#{file}"
      rescue
        client_socket.puts "HTTP/1.1 404 Not Found\r\n\r\n"
      end
    else
      content = client_socket.read(headers['Content-Length'].to_i)
      begin
        File.write(file_path, content)
        client_socket.puts "HTTP/1.1 201 Created\r\n\r\n"
      rescue
        client_socket.puts "HTTP/1.1 404 Not Found\r\n\r\n"
      end
    end
  else
    client_socket.puts "HTTP/1.1 404 Not Found\r\n\r\n"
  end
  client_socket.close
end
