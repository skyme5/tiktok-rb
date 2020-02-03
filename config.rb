#!/bin/ruby
# frozen_string_literal: true

require 'json'

def notfound(list, id)
  !list.to_json.include? id.strip
end

PATH = '/media/drive/b/Scripts/tiktok/config.json'

list = JSON.parse(File.read(PATH))

if notfound(list, ARGV[0])
  list.unshift(
    fullname: ARGV[2].strip,
    id: ARGV[0].strip,
    username: ARGV[1].strip
  )

  out = File.open(PATH, 'w')
  out.puts JSON.pretty_generate(list)
  out.close
end
