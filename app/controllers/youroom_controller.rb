require 'oauth'
require 'json'
require 'oauth_consumer'

class YouroomController < ApplicationController
  unloadable
  include OauthConsumer
 
  before_filter :find_project,:only => :register
  before_filter :authorize,:only => :register
 
  def get_access_token
    
    default_port = (request.scheme=="http") ? 80:443
    port = (request.port == default_port) ? "" : ":#{request.port.to_s}"
    
      callback_url = "#{request.scheme}://#{request.host}#{port}/youroom/access_token"
      request_token = oauth_consumer.get_request_token(:oauth_callback => callback_url)
      session[:request_token] = request_token.token
      session[:request_token_secret] = request_token.secret
      session[:context] = params

      redirect_to request_token.authorize_url
  end

  def access_token 
    request_token = OAuth::RequestToken.new(
      oauth_consumer, session[:request_token], session[:request_token_secret])
    begin
      @access_token_obj = request_token.get_access_token(
        {},
        :oauth_token => params[:oauth_token],
        :oauth_verifier => params[:oauth_verifier])
    rescue OAuth::Unauthorized => @exception
    end
    oauth_token = OauthToken.find_by_user_id(User.current.id)

    if oauth_token.nil?
      OauthToken.create(:user_id => User.current.id,:access_token => @access_token_obj.token,:access_secret => @access_token_obj.secret)
    else
      oauth_token.update_attributes(:access_token => @access_token_obj.token,:access_secret => @access_token_obj.secret)
    end

    context = session[:context]
    context[:controller] = 'issues'
    context[:action] = context[:notes] ? 'edit' : 'new'
    redirect_to :params => context

  end

  def register
    @project_room = ProjectRoom.find_by_project_id(Project.find(params[:project_id]).id)
    if @project_room.blank?
      @room_url="http://www.youroom.in";
    else  
      @room_url = @project_room.room_num.blank? ? "http://www.youroom.in/" : "https://www.youroom.in/r/#{@project_room.room_num}/"
    end
  end

  def update 
    project_id = Project.find(params[:project_id]).id
    room_num = params[:project_room][:room_num]
    post_check = params[:project_room][:post_check]
    @project_room = ProjectRoom.find_by_project_id(project_id)
    if @project_room.nil?
      ProjectRoom.create({:project_id => project_id}.merge params[:project_room])
    else
      @project_room.update_attributes(params[:project_room])
    end
    flash[:notice] = "registered!"
    @project = Project.find(params[:project_id])
    redirect_to :action => 'register',:project_id => @project
  end

  def find_project
    # @project variable must be set before calling the authorize filter
    @project = Project.find(params[:project_id])
  end

end
