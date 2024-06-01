require "socket"
require "zlib"
require 'base64'
require 'stringio'

server = TCPServer.new("localhost", 4221)

loop do
  client_socket, client_address = server.accept
  request = client_socket.gets
  verb, path, protocol = request.split(" ")
  headers = {}
  while line = client_socket.gets.split(" ", 2)
    break if line[0] == ""
    headers[line[0].chop.downcase!] = line[1].strip
  end
  case path
  when "/"
    client_socket.puts "HTTP/1.1 200 OK\r\n\r\n"
  when /\/echo\/.*/
    content = path.split("/").last
    invalid_headers = []
    gzip = false
    headers["accept-encoding"]&.split(', ')&.each do |header|
      if header != "gzip"
        invalid_headers << header
      else
        gzip = true
      end
    end
    def enconding_string(value)
      buffer = StringIO.new
      gzip_writer = Zlib::GzipWriter.new(buffer)
      gzip_writer.write(value)
      gzip_writer.close
      buffer.string
    end
    if invalid_headers.any? && gzip
      compressed_data = enconding_string(content)
      client_socket.puts "HTTP/1.1 200 OK\r\nContent-Encoding: gzip\r\nContent-Type: text/plain\r\nContent-Length:#{compressed_data.length}\r\n\r\n#{compressed_data}"
    elsif invalid_headers.any?
      client_socket.puts "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length:#{content.length}\r\n\r\n#{content}"
    else
      compressed_data = enconding_string(content)
      puts compressed_data.length
      client_socket.puts "HTTP/1.1 200 OK\r\nContent-Encoding: gzip\r\nContent-Type: text/plain\r\nContent-Length:#{compressed_data.size}\r\n\r\n#{compressed_data}"
    end
  when /\/user-agent/
    agent = headers["user-agent"]
    client_socket.puts "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: #{agent.length}\r\n\r\n#{agent}"
  when /\/files/
    filename = path.split("/").last
    directory = ARGV[1]
    file_path = directory+filename
    if verb == "GET"
      begin
        file = File.open("#{file_path}", "r").read
        client_socket.puts "HTTP/1.1 200 OK\r\nContent-Type: application/octet-stream\r\nContent-Length: #{file.length}\r\n\r\n#{file}"
      rescue
        client_socket.puts "HTTP/1.1 404 Not Found\r\n\r\n"
      end
    else
      content = client_socket.read(headers["content-length"].to_i)
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
