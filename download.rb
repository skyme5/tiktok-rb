#!/usr/bin/ruby
# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

def request(path, data)
  uri = URI.parse('http://127.0.0.1:3232')

  http = Net::HTTP.new(uri.host, uri.port)

  request = Net::HTTP::Post.new(path)
  request.add_field('Content-Type', 'application/json; charset=utf-8')
  request.body = data.to_json

  response = http.request(request)

  JSON.parse(response.body)
end

users = JSON.parse(File.read('config.json'))

length = users.length
users.each_with_index do |user, index|
  next if !user['download'].nil? && !user['download']

  status = "[#{index}/#{length}]"
  userinfo = "#{user['username']}, #{user['fullname']}"
  puts "Downloading User => #{status} #{userinfo}"
  request('/api/v2/tiktok/download',
          'id' => user['id'],
          'download_all' => user['download_all'],
          'url' => "https://www.tiktok.com/#{user['username']}")
  sleep(120)
end
