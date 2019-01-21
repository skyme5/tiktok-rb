require 'json'
require 'base64'
require 'net/http'
require 'net/https'
require 'open-uri'
require 'uri'
require 'thread'
require 'colorize'
require 'logger'
require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

class String
  def fix(size, padstr=' ')
    self[0...size].ljust(size, padstr) #or ljust
  end
end

$LOG = Logger.new(STDOUT)

# https://t.tiktok.com/aweme/v1/aweme/favorite/?user_id=6573125246566678529&count=1&max_cursor=0&aid=1180&_signature=
# https://t.tiktok.com/aweme/v1/aweme/favorite/?user_id=6573125246566678529&count=21&max_cursor=0&aid=1180&_signature=C.mUYBAHUCuDzGW4BW0ZuAv5lH
$start = Time.now

class TikTok
  def initialize(user_id, count)
    @_name = "TikTok"
    @_version = "0.0.1"
    @_user_id = user_id;
    @_count = count
    @_max_cursor = 50
    @count = 0
    @downloaded = [] #File.open("B:/TikTok/downloaded.txt").read.split("\n")
    @downloaded << Time.now
    @list = []
    @valid_url_regexp = /^http\:\/\// #/\A#{URI::regexp(['http', 'https'])}\z/
  end

  def getJSON
    query = [
      "/api/v2/tiktok",
      "#{@_count}",
      "#{@_max_cursor}"
    ].join("/")

    $LOG.info "Fetching aweme_list from TikTok ... #{query}"
    uri = URI.parse("https://localhost")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(query)
    response = http.request(request)
    return JSON.parse(response.body)
  end

  def submitToDB(data)
    query = "/api/v2/tiktok"
    uri = URI.parse("https://localhost")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Post.new(query)
    request.add_field('Content-Type', 'application/json')
    request.body = data.to_json
    response = http.request(request)
    responseBody = JSON.parse(response.body)
    $LOG.debug "Submit data to localhost ... "
    $LOG.debug "Server response OK #{responseBody["message"]}" if responseBody["success"]
    $LOG.error response.body if !JSON.parse(response.body)["success"]
  end

  def valid_url(url)
    # url_regexp = /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/ix
    url_regexp = /^(http|s3|az)/ix
    url =~ url_regexp ? true : false
  end

  def t_url_label_large(data)
    list = []
    begin
      return list if data["label_large"].nil?
      list << data["label_large"]["uri"] if valid_url(data["label_large"]["uri"])
      list << data["label_large"]["url_list"].first
    rescue => detail
      $LOG.error "label_large => not found"
      # print detail.backtrace.join("\n")
    end
    list
  end

  def t_url_label_top(data)
    list = []
    begin
      list << data["label_top"]["uri"] if valid_url(data["label_top"]["uri"])
      list << data["label_top"]["url_list"].first
    rescue => detail
      print detail.backtrace.join("\n")
    end
    list
  end

  def t_url_music_cover_large(data)
    list = []
    begin
      return list if data["music"].nil? || data["music"]["cover_large"].nil?
      list << data["music"]["cover_large"]["uri"] if valid_url(data["music"]["cover_large"]["uri"])
      list << data["music"]["cover_large"]["url_list"].first
    rescue => detail
      print detail.backtrace.join("\n")
    end
    list
  end

  def t_url_music_play_url(data)
    list = []
    begin
      return list if data["music"].nil? || data["music"]["play_url"].nil?
      list << data["music"]["play_url"]["uri"] if valid_url(data["music"]["play_url"]["uri"])
      list << data["music"]["play_url"]["url_list"].first
    rescue => detail
      print detail.backtrace.join("\n")
    end
    list
  end

  def t_url_author_avatar_large(data)
    list = []
    begin
      return list if data["author"].nil? || data["author"]["avatar_larger"].nil?
      list << data["author"]["avatar_larger"]["uri"] if valid_url(data["author"]["avatar_larger"]["uri"])
      list << data["author"]["avatar_larger"]["url_list"].first
    rescue => detail
      print detail.backtrace.join("\n")
    end
    list
  end

  def t_url_author_avatar_thumb(data)
    list = []
    begin
      return list if data["author"].nil? || data["author"]["avatar_thumb"].nil?
      list << data["author"]["avatar_thumb"]["uri"] if valid_url(data["author"]["avatar_thumb"]["uri"])
      list << data["author"]["avatar_thumb"]["url_list"].first
    rescue => detail
      print detail.backtrace.join("\n")
    end
    list
  end

  def t_url_video_cover(data)
    list = []
    begin
      return list if data["video"].nil? || data["video"]["cover"].nil?
      list << data["video"]["cover"]["uri"] if valid_url(data["video"]["cover"]["uri"])
      list << data["video"]["cover"]["url_list"].first
    rescue => detail
      print detail.backtrace.join("\n")
    end
    list
  end

  def t_url_video_cover_dynamic(data)
    list = []
    begin
      return list if data["video"].nil? || data["video"]["dynamic_cover"].nil?
      list << data["video"]["dynamic_cover"]["uri"] if valid_url(data["video"]["dynamic_cover"]["uri"])
      list << data["video"]["dynamic_cover"]["url_list"].first
    rescue => detail
      print detail.backtrace.join("\n")
    end
    list
  end

  def t_url_video_play_ddr(data)
    list = []
    begin
      return list if data["video"].nil? || data["video"]["play_addr"].nil?
      list << data["video"]["play_addr"]["uri"] if valid_url(data["video"]["play_addr"]["uri"])
      list << data["video"]["play_addr"]["url_list"].first
    rescue => detail
      print detail.backtrace.join("\n")
    end
    list
  end

  def combineURLCalls(data)
    url_list = []
    url_list << t_url_label_large(data)
    url_list << t_url_label_top(data)
    url_list << t_url_music_cover_large(data)
    url_list << t_url_music_play_url(data)
    url_list << t_url_author_avatar_large(data)
    url_list << t_url_author_avatar_thumb(data)
    url_list << t_url_video_cover(data)
    url_list << t_url_video_cover_dynamic(data)
    url_list << t_url_video_play_ddr(data)

    url_list = url_list.flatten.compact

    $LOG.debug "URL_FOUND => #{url_list.length}"

    url_list.map!{
      |url|
      url = "http" + url.split("http").last
      url.gsub("s3://musically-prod", "http://musically-prod.s3.amazonaws.com")
      .gsub(/^\/\//, "http://")
      .gsub("https://p3.pstatp.com/obj/http", "http")
      .gsub("http://p3.pstatp.com", "http://p16-tiktokcdn-com.akamaized.net")
      .gsub("http//", "http://")
    }
    url_list
  end

  def getMediaURLS(data)
    base = data["aweme_id"]
    reg = /(https?:)?\/\/[^\/]+/

    items = combineURLCalls(data)

    items.each {
      |url|
      next if url.nil?
      next if @downloaded.include? url
      @downloaded << url if !@downloaded.include? url
      uri = URI(url.gsub(/^\/\//, "http://").gsub("?video_id=", "").gsub(/&/, "?"))
      @list << {
        "url" => url.gsub(/^\/\//, "http://"),
        "path" => "B:/TikTok/" + base + uri.path
      }
    }
  end

  def getRecursive()
    data = getJSON()
    @_count = data["start"]
    for aweme in data["results"]
      getMediaURLS(aweme)
      # submitToDB(aweme)
    end

    if data["has_more"] && @_count <= 50
      $LOG.debug "It has more posts #{@count} => #{@_count} => #{@_max_cursor}"
      getRecursive();
    end
  end

  def prepareDownloadList
    list = @list.map{
      |a|

      fname = File.basename(a["path"])
      dir = File.dirname(a["path"])
      {
        "url" => a["url"],
        "dir" => dir,
        "fname" => fname,
        "path" => a["path"]
      }
    }

    _index = 0
    _length = list.length
    _download = 0
    _url_all = File.open("B:/Scripts/tiktok/urls_all.txt", "w")
    list.select!{
      |url|
      print "\r[#{url["url"].fix(100)}] (#{_index}/#{_download}/#{_length}) checking url"
      $stdout.flush
      no_exist = !File.exist?(url["path"])
      _download = _download + 1 if no_exist
      _index = _index + 1
      _url_all.puts url["url"] if no_exist
      no_exist
    }
    print "\n"
    _url_all.close

    list.map!{
      |a|
      [
        a["url"],
        "    dir=" + a["dir"],
        "    out=" + a["fname"]
      ].join("\n")
    }

    downloaded = File.open("B:/Scripts/tiktok/urls_downloaded.txt", "w")
    downloaded.puts @downloaded.join("\n")
    downloaded.close

    $LOG.info "Saving media urls for download => list.txt"
    out = File.open("B:/Scripts/tiktok/urls_new.txt", "w")
    out.puts list.join("\n").strip
    out.close

    $LOG.debug "Downloading media files"
    system("aria2c --auto-file-renaming=false --continue=true -i B:/Scripts/tiktok/urls_new.txt")
  end

  def getAll()
    $LOG.info "Fetching posts ... "
    getRecursive()
    prepareDownloadList()
    $LOG.info "#{@count} New media downloaded"
    $LOG.debug "Finish job in #{Time.now() - $start} seconds"
  end
end

tik = TikTok.new(6573125246566678529, 0);
tik.getAll();
