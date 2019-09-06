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
# https://t.tiktok.com/i18n/share/user/6516360574120673282
$start = Time.now

class TikTok
  def initialize(config)
    @_name = "TikTok"
    @_version = "0.0.1"
    @config = config
    @cursor = { "max" => 0, "min" => 0}
    @count = 0
    @aweme = []
    @list = []
    @max_limit = 1300
  end

  def getJSON
    query = [
      @config["path"],
      "?",
      "user_id=#{@config["user_id"]}",
      "&count=#{@config["count"]}",
      "&max_cursor=#{@cursor["max"]}",
      "&aid=1180",
      "&_signature=#{@config["_signature"]}"
    ].join("")

    p "https://" + @config["Host"] + query

    $LOG.info "Fetching aweme_list from TikTok ... #{query}".upcase
    uri = URI.parse("https://" + @config["Host"])
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(query)
    request['Host'] = @config["Host"]
    request['Referer'] = @config["Referer"]
    request['User-Agent'] = 'Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.71 Safari/537.36'
    request['Sec-Metadata'] = 'destination=empty, site=same-origin'
    request['x-requested-with'] = 'XMLHttpRequest'
    response = http.request(request)
    return JSON.parse(response.body)
  end

  def requestCheck(path, data)
    uri = URI.parse("https://localhost")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Post.new(path)
    request.add_field('Content-Type', 'application/json; charset=utf-8')
    request.body = data.to_json
    response = http.request(request)
		begin
			return JSON.parse(response.body)
		rescue
			p data
			return {"exist" => false}
		end
  end

  def submitToDB(data)
		begin
			query = "/api/v2/tiktok"
			uri = URI.parse("https://localhost")
			http = Net::HTTP.new(uri.host, uri.port)
			http.use_ssl = true
			http.verify_mode = OpenSSL::SSL::VERIFY_NONE
			request = Net::HTTP::Post.new(query)
			request.add_field('Content-Type', 'application/json; charset=utf-8')
			request.body = data.to_json.force_encoding("UTF-8")
			response = http.request(request)
			responseBody = JSON.parse(response.body)
			$LOG.debug "Submit data to localhost ... ".upcase
			$LOG.debug "Server response OK #{responseBody["message"]}".upcase if responseBody["success"]
			$LOG.error response.body if !JSON.parse(response.body)["success"]
			return response.body.to_s.include? "AWEME_UPDATED" if !@config["download_all"]
			return false if @config["download_all"]
		rescue
			return false
		end
  end

  def valid_url(url)
    # url_regexp = /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/ix
    url_regexp = /^(http|s3|az|\/\/)/ix
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

  def formatURL(url)
    if url.include?("s3://")
      url = "http://musically-prod.s3.amazonaws.com" + url.split("s3://").last
    end
    if url.include?("az://")
      url = "http://musically-prod.s3.amazonaws.com" + url.split("s3://").last
    end

    if url.match(/^http:\/\/p3\.pstatp\.com/)
      url = url.gsub(/^http:\/\/p3\.pstatp\.com/, "http://p16-tiktokcdn-com.akamaized.net")
    end

    return url

    # url.gsub("s3://musically-prod", "http://musically-prod.s3.amazonaws.com")
    # .gsub(/^\/\//, "http://")
    # .gsub("https://p3.pstatp.com/obj/http", "http")
    # .gsub("http://p3.pstatp.com", "http://p16-tiktokcdn-com.akamaized.net")
    # .gsub("http//", "http://")
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
      formatURL(url)
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
      uri = URI(url.gsub(/^\/\//, "http://").gsub("?video_id=", "").gsub(/&/, "?"))
      @list << {
        "url" => url.gsub(/^\/\//, "http://"),
        "path" => "B:/TikTok/" + base + uri.path
      }
    }
  end

  def awemeExist(aweme_id)
    response = requestCheck("/api/v2/tiktok/" + aweme_id + "/exist", {"aweme_id" => aweme_id})
    response["exist"]
  end

  def getRecursive()
    data = getJSON()
    @count += data["aweme_list"].length
    $LOG.debug "aweme fetch done for => #{@config["user_id"]} found #{data["aweme_list"].length} aweme".upcase
    for aweme in  data["aweme_list"]
      aweme_exist = awemeExist(aweme["aweme_id"])
      if !aweme_exist
        getMediaURLS(aweme)
        @aweme << aweme
      end
      return if aweme_exist && !@config["download_all"]
    end

    if !data["has_more"].nil? && data["has_more"] == 1
      @cursor["max"] = data["max_cursor"]
      $LOG.debug "It has more posts #{@count} => #{@config["count"]} => #{@cursor["max"]}".upcase
      getRecursive();
    end
  end

  def prepareDownloadList
    list = @list.map{
      |link|
      filename = File.basename(link["path"]).split("&").first
      directory = File.dirname(link["path"])
      {
        "url" => link["url"],
        "directory" => directory,
        "filename" => filename,
        "path" => link["path"]
      }
    }

    list.select!{
      |link|
      !File.exist?(link["path"])
    }
    return list
  end

  def saveToDB
    @aweme.reverse.each{
      |aweme|
      submitToDB(aweme)
    }
  end

  def get()
    $LOG.info "Fetching posts ... ".upcase
    begin
      getRecursive()
      saveToDB()
      list = prepareDownloadList()
      $LOG.info "#{@count} New media to download".upcase
      $LOG.debug "Finish job in #{Time.now() - $start} seconds".upcase
      return list
    rescue
      return []
    end
  end
end
