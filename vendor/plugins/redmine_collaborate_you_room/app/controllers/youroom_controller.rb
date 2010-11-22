require 'oauth'
require 'json'

class YouroomController < ApplicationController
  unloadable
 
  before_filter :find_project,:only => :room_registry
  before_filter :authorize,:only => :room_registry
 
  def post_to_youroom request
    issue = Issue.find_all_by_author_id(User.current.id).last
    project = issue.project

    default_port = (request.scheme=="http") ? 80:443
    port = (request.port == default_port) ? "" : ":#{request.port.to_s}"
    root_url = "#{request.scheme}://#{request.host}#{port}"

   access_token_obj = OAuth::AccessToken.new(oauth_consumer, OauthToken.find_by_user_id(User.current.id).access_token, OauthToken.find_by_user_id(User.current.id).access_secret)
   

   tag = '#Redmine'
   issue_status = "[#{issue.status}]"
   issue_id = "Number : #{issue.id}"
   issue_subject = "Subject : #{issue.subject}"
   pj_name = "PJ Name : #{project.name}"
   room_num = ProjectRoom.find_by_project_id(project.id).room_num 
   issue_url = "#{root_url}/issue/#{issue.id}"
   
   entry = %W|#{tag} #{issue_status} #{issue_url} #{issue_id} #{issue_subject} #{pj_name}|.join("\r\n")
   entry = entry[0..139] if entry.size >= 140
   entry_param =  {"entry[content]"=>"#{entry}"}
   
  #POST
p   post_res = access_token_obj.post("https://www.youroom.in/r/#{room_num}/entries?format=json", entry_param)

  end


  def get_access_token
      callback_url = "#{base_url}/youroom/access_token"
      request_token = oauth_consumer.get_request_token(:oauth_callback => callback_url)
      session[:continue] = params[:continue]
      session[:request_token] = request_token.token
      session[:request_token_secret] = request_token.secret
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

   # User.current.update_attributes (:access_token => @access_token_obj.token,:access_secret => @access_token_obj.secret)

    post_to_youroom request

    post_issue = Issue.find_all_by_author_id(User.current.id).last
  #  project_identifier = post_issue.project.identifier
    project = post_issue.project

    redirect_to(session[:continue] ? { :controller => 'issues', :action => 'new', :project_id => project.id,:issue => {:tracker_id => post_issue.tracker, :parent_issue_id => post_issue.parent_issue_id}.reject {|k,v| v.nil?} } :
                      { :controller => 'issues' , :action => 'show', :id => post_issue })
  end

  def room_registry
    p @project = Project.find_by_identifier(params[:project_id])
    @project_room = ProjectRoom.find_by_project_id(2)
  end

  def room_update
    project_id = params[:project][:project_id]
    room_num = params[:project][:room_num]
    @project_room = ProjectRoom.find_by_project_id(project_id)
    if @project_room.nil?
      ProjectRoom.create(:project_id => project_id,:room_num => room_num)
    else
      @project_room.update_attributes(:room_num => room_num)
    end
    flash[:notice] = "登録しました。"
    @project = Project.find(params[:project][:project_id])
    #@project.update_attributes(:room_num => room_num)
    redirect_to :action => 'room_registry',:project_id => @project
  end

  private
  def base_url
    default_port = (request.scheme=="http") ? 80:443
    port = (request.port == default_port) ? "" : ":#{request.port.to_s}"
    "#{request.scheme}://#{request.host}#{port}"
  end

  def oauth_consumer
    OAuth::Consumer.new(CONSUMER_KEY,CONSUMER_SECRET, :site => "http://youroom.in")
  end

  def find_project
    # @project variable must be set before calling the authorize filter
    @project = Project.find(params[:project_id])
  end

end
