#!/usr/bin/ruby
# frozen_string_literal: true

# @Author: Sky
# @Date:   2019-01-28 14:40:35
# @Last Modified by:   Sky
# @Last Modified time: 2019-09-08 19:36:18

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

  puts "Downloading User => [#{index}/#{length}] #{user['username']}, #{user['fullname']}"
  request('/api/v2/tiktok/download',
          'id' => user['id'],
          'download_all' => user['download_all'],
          'url' => "https://www.tiktok.com/#{user['username']}")
  sleep(120)
end

# puts "Downloading media files"
# #sleep(260)
# system([
#          "aria2c",
#          "-q",
#          "-x16",
#          "-s16",
#          "--user-agent=\"Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.65 Safari/537.36\"",
#          "--auto-file-renaming=false",
#          "--continue=true",
#          "-i /media/drive/b/Scripts/tiktok/urls_new.txt"
# ].join(" "))
#
# puts "Finish downloading media files"

# system("copy urls_new.txt #{Time.now.strftime('%Y-%m-%d_%H-%M-%S')}_urls_new.txt")
# system("del urls_new.txt")
