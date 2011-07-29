class IssueListener < Redmine::Hook::ViewListener
=begin
  def view_issues_form_details_bottom (context)
    issue = context[:issue] 
    form = context[:form]
    p "issue start========================="
    p issue
    p "issue end = form start =========================="
    p form
    p "form end==========================="
    html = '<hr>'
    html += "<div><%= check_box_tag :youroom,value = true,checked = @project_room.nil? ? false : @project_room.post_check %> youRoomへ投稿する</div>"
    html
    render_on "post_to_youroom"
  end
=end  
  render_on :view_issues_form_details_bottom, :partial => "youroom/post_to_youroom" 
end
