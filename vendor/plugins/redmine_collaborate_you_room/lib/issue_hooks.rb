require 'oauth'
require 'json'
require 'date'

class IssueHook < Redmine::Hook::Listener
  KEY = "twHMFWVkNhCBQaaaEiCg" 
  SECRET = "damJeepVucxKtgVVh7yaGpLUoN1nVMrT6pF7cZW4"
  ACCESS_TOKEN="zgA6pMd2xPbO6iIroCJt"
  ACCESS_TOKEN_SECRET="P1uofaRZh2wKEMtt6VBqxBSQikKS0nO4QYuiNFvC"

  def oauth_consumer
    OAuth::Consumer.new(KEY,SECRET, :site => "http://youroom.in")
  end

  def base_url request
    default_port = (request.scheme=="http") ? 80:443
    port = (request.port == default_port) ? "" : ":#{request.port.to_s}"
    "#{request.scheme}://#{request.host}#{port}"
  end

  def controller_issues_new_after_save context
    request = context[:request]
    current_user = User.current
    params = context[:params]
    if params[:youroom]
      if current_user.access_token.blank? || current_user.access_secret.blank?
        return false
      elsif
        post current_user.access_token,current_user.access_secret
      end
    end
  end


  def post access_token,access_secret
   access_token_obj = OAuth::AccessToken.new(oauth_consumer, access_token, access_secret)
   
#POST sample
   param = {:entry => {:content => "post_test #{Date.today}"}} 
#   p Hash[URI.decode(param.to_query).split('&').map{|item|item.split('=')}] # => {"entry[content]" => "本文", "entry[parent_id]" => "3"}

#   @post_res = @access_token.post('https://www.youroom.in/r/773/entries?format=json', Hash[URI.decode(param.to_query).split('&').map{|item|item.split('=')}])
  post_res = access_token_obj.post('https://www.youroom.in/r/773/entries?format=json', {"entry[content]"=>"#Redmine \r\n Post test #{Date.today}"})

  end
end
