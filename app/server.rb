require "socket"

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
    if headers['Accept-Encoding'] == 'gzip'
      client_socket.puts "HTTP/1.1 200 OK\r\nContent-Encoding: gzip\r\nContent-Type: text/plain\r\nContent-Length:#{content.length}\r\n\r\n#{content}"
    else
      client_socket.puts "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length:#{content.length}\r\n\r\n#{content}"
    end
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
