require 'rubygems'
require 'oauth'
require 'json'
require 'date'
require 'oauth_consumer'

class IssueHook < Redmine::Hook::Listener
  include OauthConsumer

  MAX_ENTRY_LENGHT = 280

  def controller_issues_new_after_save context
      post_to_youroom context unless context[:params][:youroom].blank?
  end

  def controller_issues_edit_after_save context
      post_to_youroom context unless context[:params][:youroom].blank?
  end

  private
  def post_to_youroom context
    context[:request] = context[:params][:request] if context[:request].blank?
    issue = context[:issue]
    room_num = ProjectRoom.find_by_project_id(issue.project.id).room_num 

    entry_params = create_entry_params context, room_num

    oauth_token = OauthToken.find_by_user_id(User.current.id)
    access_token_obj = OAuth::AccessToken.new(oauth_consumer, oauth_token.access_token, oauth_token.access_secret)
    post_res = access_token_obj.post("https://www.youroom.in/r/#{room_num}/entries?format=json", entry_params)

    if post_res.code == '201'
      thread_id = JSON.parse(post_res.body)["entry"]["root_id"]
      YouRoomThread.create(:thread_id => thread_id, :issue_id => issue.id)
    elsif post_res.code == '422'
      thread = YouRoomThread.find_by_issue_id(context[:issue].id)
      unless thread.blank?
        thread.delete
        post_to_youroom context
      end
    end
  end


  def create_entry_params context, room_num
    issue = context[:issue]
    room_thread =  YouRoomThread.find_by_issue_id(issue.id)
    project = issue.project
    tag = '#Redmine'
    issue_status = "St: #{issue.status}"
    issue_priority = "Pri: #{issue.priority.name}"

    entry = ""

    if room_thread.nil?
      issue_subject = "【#{issue.subject}】"
      issue_subject = issue_subject.split(//u)[0,22] << "..." if issue_subject.split(//u).size > 25 
      pj_name = "- #{project.name} -"
      issue_url = "#{base_url context[:request]}/issues/#{issue.id}"
      entry = (%W|#{tag} #{issue_status} #{issue_priority} #{issue_subject} #{issue_url} #{pj_name}|).join("\r\n")
    else
      issue_notes = context[:params][:notes]
      entry = (%W|#{issue_status} #{issue_priority} \r\nNote: #{issue_notes}|).join("\r\n")
    end

    entry = "#{entry.split(//u)[0,MAX_ENTRY_LENGTH-5]}..." if entry.split(//u).size >= MAX_ENTRY_LENGHT
    entry_params =  {"entry[content]"=>"#{entry}"} 
    entry_params.merge! "entry[parent_id]" => room_thread.thread_id unless room_thread.nil?
    return entry_params
  end

  def base_url request
    default_port = (request.scheme=="http") ? 80:443
    port = (request.port == default_port) ? "" : ":#{request.port.to_s}"
    "#{request.scheme}://#{request.host}#{port}"
  end

end
