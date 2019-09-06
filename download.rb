#!/usr/bin/ruby
# @Author: Sky
# @Date:   2019-01-28 14:40:35
# @Last Modified by:   Sky
# @Last Modified time: 2019-04-20 12:51:48

require_relative "TikTok"

users = JSON.parse(File.read("config.json"))

def save_links(list)
  download = list.flatten.map!{
    |url|
    [
      url["url"],
      "    dir=" + url["directory"],
      "    out=" + url["filename"].split("&")[0]
    ].join("\n")
  }

  out = File.open("B:/Scripts/tiktok/urls_new.txt", "a")
  out.puts download.join("\n")
  out.close
end

for user in users
  tiktok = TikTok.new(user)
  save_links(tiktok.get())
end

system("aria2c --auto-file-renaming=false --continue=true -i B:/Scripts/tiktok/urls_new.txt")
