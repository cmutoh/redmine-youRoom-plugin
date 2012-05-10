require 'oauth'
module OauthConsumer
  CONSUMER_KEY = "*****************" #youRoomから取得したCONSUMER_KEYを設定
  CONSUMER_SECRET = "********************" #youRoomから取得したCONSUMER_SECRETを設定

  def oauth_consumer
    OAuth::Consumer.new(CONSUMER_KEY,CONSUMER_SECRET, :site => "http://youroom.in")
  end
end
