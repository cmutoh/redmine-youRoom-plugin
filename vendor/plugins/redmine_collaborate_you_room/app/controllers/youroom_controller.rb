require 'oauth'
require 'json'

class YouroomController < ApplicationController
  unloadable
 
  before_filter :find_project,:only => :room_registry
  before_filter :authorize,:only => :room_registry
 
  def self.post_to_youroom request, notes, id

    oauth_consumer = OAuth::Consumer.new(CONSUMER_KEY,CONSUMER_SECRET, :site => "http://youroom.in")
  
    issue = Issue.find(id)
    project = issue.project

    default_port = (request.scheme=="http") ? 80:443
    port = (request.port == default_port) ? "" : ":#{request.port.to_s}"
    root_url = "#{request.scheme}://#{request.host}#{port}"

    access_token_obj = OAuth::AccessToken.new(oauth_consumer, OauthToken.find_by_user_id(User.current.id).access_token, OauthToken.find_by_user_id(User.current.id).access_secret)

    room_thread =  YouRoomThread.find_by_issue_id(issue.id)

    tag = '#Redmine'
    issue_status = "St: #{issue.status}"
    issue_priority = "Pri: #{issue.priority.name}"
    room_num = ProjectRoom.find_by_project_id(project.id).room_num 

    issue_subject = "【#{issue.subject}】"
    issue_subject = issue_subject.split(//u)[0,22] << "..." if issue_subject.split(//u).size > 25 
    pj_name = "- #{project.name} -"
    issue_url = "#{root_url}/issues/#{issue.id}"

    issue_notes = notes

    entry = (room_thread.nil? ? %W|#{tag} #{issue_status} #{issue_priority} #{issue_subject} #{issue_url} #{pj_name}| : %W|#{issue_status} #{issue_priority} \r\nNote: #{issue_notes}|).join("\r\n")

    entry = "#{entry.split(//u)[0,135]}..." if entry.split(//u).size >= 140

    entry_param =  {"entry[content]"=>"#{entry}"} 
    entry_param.merge! "entry[parent_id]" => room_thread.thread_id unless room_thread.nil?
    #POST
    post_res = access_token_obj.post("https://www.youroom.in/r/#{room_num}/entries?format=json", entry_param)

    if room_thread.nil?
      thread_id = JSON.parse(post_res.body)["entry"]["root_id"]
      YouRoomThread.create(:thread_id => thread_id, :issue_id => issue.id)
    elsif post_res.code == '422'
      entry = %W|#{tag} #{issue_status} #{issue_priority} #{issue_url} #{issue_subject} #{pj_name}|.join("\r\n")

      entry = "#{entry.split(//u)[0,135]}..." if entry.split(//u).size >= 140

      entry_param =  {"entry[content]"=>"#{entry}"} 
p      post_res = access_token_obj.post("https://www.youroom.in/r/#{room_num}/entries?format=json", entry_param)
      thread_id = JSON.parse(post_res.body)["entry"]["root_id"]
      room_thread.update_attributes(:thread_id => thread_id)
    end

  end


  def get_access_token
    
    default_port = (request.scheme=="http") ? 80:443
    port = (request.port == default_port) ? "" : ":#{request.port.to_s}"
    
      callback_url = "#{request.scheme}://#{request.host}#{port}/youroom/access_token"
      request_token = oauth_consumer.get_request_token(:oauth_callback => callback_url)
      session[:continue] = params[:continue]
      session[:request_token] = request_token.token
      session[:request_token_secret] = request_token.secret
      session[:notes] = params[:notes]
      session[:issue_id] = params[:issue_id]

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

    #post処理
    self.post_to_youroom request, session[:notes], session[:issue_id]

    post_issue = Issue.find(session[:issue_id])  #  project_identifier = post_issue.project.identifier
    project = post_issue.project

    redirect_to(session[:continue] ? { :controller => 'issues', :action => 'new', :project_id => project.id,:issue => {:tracker_id => post_issue.tracker, :parent_issue_id => post_issue.parent_issue_id}.reject {|k,v| v.nil?} } :
                      { :controller => 'issues' , :action => 'show', :id => post_issue })
  end

  def room_registry
    @project_room = ProjectRoom.find_by_project_id(Project.find(params[:project_id]).id)
    @room_url = @project_room.room_num.blank? ? "http://www.youroom.in/" : "https://www.youroom.in/r/#{@project_room.room_num}/"
  end

  def room_update
    project_id = Project.find(params[:project_id]).id
    room_num = params[:project_room][:room_num]
    post_check = params[:project_room][:post_check]
    @project_room = ProjectRoom.find_by_project_id(project_id)
    if @project_room.nil?
      ProjectRoom.create({:project_id => project_id}.merge params[:project_room])
    else
      @project_room.update_attributes(params[:project_room])
    end
    flash[:notice] = "登録しました。"
    @project = Project.find(params[:project_id])
    redirect_to :action => 'room_registry',:project_id => @project
  end

  private
  def oauth_consumer
    OAuth::Consumer.new(CONSUMER_KEY,CONSUMER_SECRET, :site => "http://youroom.in")
  end

  def find_project
    # @project variable must be set before calling the authorize filter
    @project = Project.find(params[:project_id])
  end

end
