require 'json'
require 'base64'
require 'net/http'
require 'net/https'
require 'open-uri'
require 'uri'
require 'thread'
require 'coloredlogger'
require 'logger'
require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

class String
  def fix(size, padstr=' ')
    self[0...size].ljust(size, padstr) #or ljust
  end
end

# https://t.tiktok.com/aweme/v1/aweme/favorite/?user_id=6573125246566678529&count=1&max_cursor=0&aid=1180&_signature=
# https://t.tiktok.com/aweme/v1/aweme/favorite/?user_id=6573125246566678529&count=21&max_cursor=0&aid=1180&_signature=C.mUYBAHUCuDzGW4BW0ZuAv5lH
# https://t.tiktok.com/i18n/share/user/6516360574120673282
$start = Time.now

class TikTok
  def initialize(config)
    @_name = "TikTok"
    @_version = "2.0.1"
    @config = config
    @config["_signature"] = getSignature(@config["id"])
    @cursor = { "max" => 0, "min" => 0}
    @aweme_count = 0
    @aweme = []
    @list = []
    @max_limit = 1300
    @LOG = ColoredLogger.new(STDOUT)
  end

  def config_username
    @config["username"]
  end

  def config_host
    @config["host"]
  end

  def config_referer
    if @config["referer"].include? config_username or @config["referer"].include? "i18"
      "https://www.tiktok.com/#{config_username}?enter_from=h5_t"
    else
      "https://www.tiktok.com/@#{config_secUid}?enter_from=h5_t"
    end
  end

  def config_path
    @config["path"]
  end

  def config_secUid
    @config["secUid"]
  end

  def config_id
    @config["id"]
  end

  def config_type
    @config["type"]
  end

  def count
    @config["count"]
  end

  def minCursor
    @cursor["min"]
  end

  def maxCursor
    @cursor["max"]
  end

  def config_signature
    logi(@config["_signature"])
    @config["_signature"]
  end

  def config_shareUid
    @config["shareUid"]
  end

  def logi(msg)
    @LOG.info(config_username, msg)
  end

  def logd(msg)
    @LOG.debug(config_username, msg)
  end

  def loge(msg)
    @LOG.error(config_username, msg)
  end

  def getJSON
    query = [
      config_path,
      "?",
      "secUid=", config_secUid,
      "&id=", config_id,
      "&type=", config_type,
      "&count=", count,
      "&minCursor=", minCursor,
      "&maxCursor=", maxCursor,
      "&_signature=", config_signature,
      "&shareUid=", config_shareUid
    ].join("")

    p "https://" + config_host + query

    logi("Fetching aweme_list from TikTok ... #{query}".upcase)

    uri = URI.parse("https://" + config_host)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(query)

    request['accept'] = "application/json, text/plain, */*"
    request['cookie'] = 'tt_webid=6727603912855209478; gr_user_id=e5f8023b-e5d6-43c4-aaa7-9e81bc2a926d; ak_bmsc=3CFECB9564EC48B7E79A241032E3FCFA1B7436856B5F0000ABC3735DD86AF47A~plFtjzdoJthqI7jROZoFITLrORP/F2X37eWa5K7s19/ljyq24qYcpfH3sBYeQRp0MGgU6Lc7ABlgWkNS/b5SoU3VskWeab23u6yY36IAlSX0OzHF09t/V5nJavZ9HcMUuxJEWQxTses+mntfe8D695UKVckRaEPi2b2ohUMFQt7Q3Q+Wq7VmcD0OM2w2eH/vmNDeC9RDlCULgL/RjmRogtGeq+1o6vslD4/gTBk7lCuZP7ZccMl8UuE4HdOT55NlKV; bm_sv=1E403C303A762B6D0140D9E80644A240~dkPgMgj/i0yA+rmo2ZoCbOPKryxx7VbeROP6DvXxjznJL1QtxysWG2nqaaW6xT5hBN5KjmcV4KYsR+ygfU5JZFUrmXyRC0+GYsH5IzqrTjh4U4/is34y4i90Tp5397ytE78tT3id0mm1u+3ug8EmyBMC7J4UIQjy3VgWxsIXZ4g='
    request['referer'] = config_referer
    request['user-agent'] = 'Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.70 Safari/537.36'

    response = http.request(request)

    data = JSON.parse(response.body)

    if data["statusCode"] != 0
      loge("Server Error encountered")
      p data
      return {"hasMore" => false, "itemListData" => []}
    else
      return data["body"]
    end
  end

  def requestCheck(path, data)
    uri = URI.parse("http://127.0.0.1:3232")

    http = Net::HTTP.new(uri.host, uri.port)

    request = Net::HTTP::Post.new(path)
    request.add_field('Content-Type', 'application/json; charset=utf-8')
    request.body = data.to_json

    response = http.request(request)

    begin
      return JSON.parse(response.body)
    rescue
      return {"exist" => false}
    end

  end

  def getSignature(user_id)
    data = open("http://127.0.0.1:3232/api/v2/tiktok/sign?user_id=#{user_id}"){ |io| io.read }
    data = JSON.parse(data)
    while data["signature"].nil? or data["signature"] == "null"
      data = open("http://127.0.0.1:3232/api/v2/tiktok/sign?user_id=#{user_id}"){ |io| io.read }
      data = JSON.parse(data)
      sleep(1)
    end

    return data["signature"]
  end

  def submitToDB(data)
    begin
      query = "/api/v2/tiktok"
      uri = URI.parse("http://127.0.0.1:3232")

      http = Net::HTTP.new(uri.host, uri.port)

      request = Net::HTTP::Post.new(query)
      request.add_field('Content-Type', 'application/json; charset=utf-8')
      request.body = data.to_json.force_encoding("UTF-8")
      response = http.request(request)

      responseBody = JSON.parse(response.body)

      logd("Submit data to localhost ... ".upcase)
      logd("Server response OK #{responseBody["message"]}".upcase) if responseBody["success"]
      loge(response.body) if !JSON.parse(response.body)["success"]

      return response.body.to_s.include? "AWEME_UPDATED" if !@config["download_all"]
      return false if @config["download_all"]
    rescue
      return false
    end
  end

  def get_media_urls(data)
    list = []

    list << data["authorInfos"]["coversLarger"].first
    list << data["authorInfos"]["coversMedium"].first
    list << data["itemInfos"]["covers"].first
    list << data["itemInfos"]["coversDynamic"].first
    list << data["itemInfos"]["coversOrigin"].first
    list << data["itemInfos"]["video"]["urls"].first
    list << data["musicInfos"]["covers"].first
    list << data["musicInfos"]["coversLarger"].first
    list << data["musicInfos"]["coversMedium"].first
    list << data["musicInfos"]["playUrl"].first

    list
  end

  def get_urls_for_Download(data)
    items = get_media_urls(data)

    items.each {
      |url|
      next if url.nil?
      uri = URI(url)
      path = uri.path
      if path.split("/").last == "/"
        path = path.split("/")
        path.pop()
        path = path.join("/")
      end

      @list << {
        "url" => url,
        "path" => "A:/TikTok_APIv2" + path
      }
    }
  end

  def awemeExist(aweme_id)
    response = requestCheck("/api/v2/tiktok/" + aweme_id + "/exist", {"aweme_id" => aweme_id})
    response["exist"]
  end

  def get_aweme(aweme)
    return {
      "aweme_id": aweme["itemInfos"]["id"],
      "author_id": aweme["itemInfos"]["authorId"],
      "children": {
        "json": aweme,
        "timestamp": Time.now.to_i,
        "version": 2
      },
      "create_time": aweme["itemInfos"]["createTime"].to_i,
      "group_id": aweme["itemInfos"]["musicId"],
      "media_type": 4,
      "user_digged": aweme["itemInfos"]["diggCount"]
    }
  end

  def getRecursive()
    data = getJSON()

    @aweme_count += data["itemListData"].length

    logd("aweme found => #{config_id} found #{data["itemListData"].length} aweme".upcase)

    for aweme in data["itemListData"]
      aweme_exist = awemeExist(aweme["itemInfos"]["id"])
      if !aweme_exist
        get_urls_for_Download(aweme)
        @aweme << get_aweme(aweme)
      end

      return if aweme_exist and !@config["download_all"]
    end

    if data["hasMore"]
      @cursor["max"] = data["maxCursor"]

      logd("It has more posts #{@aweme_count} => #{maxCursor}".upcase)
      sleep(4)
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
    logi("Fetching posts ... ".upcase)
    sleep(1)
    begin
      getRecursive()
      saveToDB()
      list = prepareDownloadList()
      logi("#{@aweme_count} New media to download".upcase)
      logd("Finish job in #{Time.now() - $start} seconds".upcase)
      return list
    rescue
      return []
    end
  end
end
