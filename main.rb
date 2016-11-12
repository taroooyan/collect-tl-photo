require 'dotenv'
require 'twitter'
Dotenv.load

class TwitterInfo
  def initialize
    @client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV["CONSUMER_KEY"]
      config.consumer_secret     = ENV["CONSUMER_SECRET"]
      config.access_token        = ENV["ACCESS_TOKEN"]
      config.access_token_secret = ENV["ACCESS_TOKEN_SECRET"]
    end
    @@since_id = 0
  end

  def media_timeline
    # エラー時の試行回数
    retries = 0

    begin
      if @@since_id == 0
        tweets = @client.home_timeline({count: 100, exclude_replies: false, include_entities: true})
      else
        tweets = @client.home_timeline({count: 100, exclude_replies: false, include_entities: true, since_id: @@since_id})
      end

    rescue Twitter::Error::TooManyRequests => error
      raise if retries >= 5
      retries += 1
      sleep error.rate_limit.reset_in
      retry
    end

    media_tweets = Array.new
    begin_id = nil

    tweets.each do |tweet|
      begin_id ||= tweet.id
      tweet.id

      # メディアがあるかどうか
      next if tweet.media.none?

      img = []
      tweet.media.each do |media|
        img << media.media_url
      end

      media_tweets << {username: tweet.user.screen_name, tweet: tweet.text, img: img}
    end
    @@since_id = begin_id
    return media_tweets
  end
end


def main
  client = TwitterInfo.new()
  loop do
    client.media_timeline().each do |tweet|
      puts tweet[:username]
      puts tweet[:tweet]
      puts tweet[:img]
      puts
    end
    sleep(60)
  end
end


main()
