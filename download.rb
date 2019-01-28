#!/usr/bin/ruby
# @Author: Sky
# @Date:   2019-01-28 14:40:35
# @Last Modified by:   Sky
# @Last Modified time: 2019-01-28 15:05:47

require_relative "TikTok"

users = JSON.parse(File.read("config.json"))

download = []

for user in users
  tiktok = TikTok.new(user)
  download << tiktok.get()
end

download.flatten!.map!{
  |url|
  [
    url["url"],
    "    dir=" + url["directory"],
    "    out=" + url["filename"].split("&")[0]
  ].join("\n")
}

out = File.open("B:/Scripts/tiktok/urls_new.txt", "a")
out.puts list.join("\n")
out.close

system("aria2c --auto-file-renaming=false --continue=true -i B:/TikTok/list.txt")
