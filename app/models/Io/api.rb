require 'net/http/persistent'

class Io::Api
  require 'net/http'
  require 'uri'
  require 'json'
  require 'faraday'

  attr_accessor :timeout

  def initialize
    @timeout = 5
  end

  # 汎用API通信メソッド
  # @param string path URL
  # @param string post_data POSTする場合のデータ(なければGET)
  # @return hash res 結果オブジェクト
  def request_api(url, post_data, header_options = {})
    conn = Faraday::Connection.new(:url => url) do |builder|
      builder.adapter Faraday::Request::UrlEncoded
      builder.adapter Faraday::Adapter::NetHttp
    end

    if post_data == '' || post_data.nil?
      res = conn.get do |req|
        req.url url
        req.headers.merge!(header_options) unless header_options.blank?
        req.options.timeout = @timeout
        req.options.open_timeout = 2
      end
    else
      res = conn.post do |req|
        req.url url
        req.headers.merge!(header_options) unless header_options.blank?
        req.body = post_data
        req.options.timeout = @timeout
        req.options.open_timeout = 2
      end
    end

    res
  rescue => e
    save_error_log(e)
  end

  def save_error_log(e)
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
  end
end
