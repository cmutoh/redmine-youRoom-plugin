require 'rubygems'
require 'oauth'
require 'json'
require 'date'

class IssueHook < Redmine::Hook::Listener
  MAX_ENTRY_LENGHT = 280

  def controller_issues_new_after_save context
      post_to_youroom context unless context[:params][:youroom].blank?
  end

  def controller_issues_edit_after_save context
      post_to_youroom context unless context[:params][:youroom].blank?
  end

  private
  def oauth_consumer
    OAuth::Consumer.new(CONSUMER_KEY,CONSUMER_SECRET, :site => "http://youroom.in")
  end

  def base_url request
    default_port = (request.scheme=="http") ? 80:443
    port = (request.port == default_port) ? "" : ":#{request.port.to_s}"
    "#{request.scheme}://#{request.host}#{port}"
  end

  def post_to_youroom context
    params = context[:params]
    request = context[:request] ||= params[:request]
    notes = params[:notes]
    id = context[:issue].id

    issue = Issue.find(id)
    project = issue.project

    access_token_obj = OAuth::AccessToken.new(oauth_consumer, OauthToken.find_by_user_id(User.current.id).access_token, OauthToken.find_by_user_id(User.current.id).access_secret)

    room_thread =  YouRoomThread.find_by_issue_id(issue.id)

    tag = '#Redmine'
    issue_status = "St: #{issue.status}"
    issue_priority = "Pri: #{issue.priority.name}"
    room_num = ProjectRoom.find_by_project_id(project.id).room_num 

    issue_subject = "【#{issue.subject}】"
    issue_subject = issue_subject.split(//u)[0,22] << "..." if issue_subject.split(//u).size > 25 
    pj_name = "- #{project.name} -"
    issue_url = "#{base_url request}/issues/#{issue.id}"

    issue_notes = notes

    entry = (room_thread.nil? ? %W|#{tag} #{issue_status} #{issue_priority} #{issue_subject} #{issue_url} #{pj_name}| : %W|#{issue_status} #{issue_priority} \r\nNote: #{issue_notes}|).join("\r\n")

    entry = "#{entry.split(//u)[0,MAX_ENTRY_LENGTH-5]}..." if entry.split(//u).size >= MAX_ENTRY_LENGHT

    entry_param =  {"entry[content]"=>"#{entry}"} 
    entry_param.merge! "entry[parent_id]" => room_thread.thread_id unless room_thread.nil?
    #POST
    post_res = access_token_obj.post("https://www.youroom.in/r/#{room_num}/entries?format=json", entry_param)

    if room_thread.nil?
      thread_id = JSON.parse(post_res.body)["entry"]["root_id"]
      YouRoomThread.create(:thread_id => thread_id, :issue_id => issue.id)
    elsif post_res.code == '422'
      entry = %W|#{tag} #{issue_status} #{issue_priority} #{issue_url} #{issue_subject} #{pj_name}|.join("\r\n")

      entry = "#{entry.split(//u)[0,MAX_ENTRY_LENGTH]}..." if entry.split(//u).size >= MAX_ENTRY_LENGTH 
      entry_param =  {"entry[content]"=>"#{entry}"} 
      post_res = access_token_obj.post("https://www.youroom.in/r/#{room_num}/entries?format=json", entry_param)
      thread_id = JSON.parse(post_res.body)["entry"]["root_id"]
      room_thread.update_attributes(:thread_id => thread_id)
    end
  end
end
