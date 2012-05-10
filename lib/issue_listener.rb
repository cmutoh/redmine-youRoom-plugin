class IssueListener < Redmine::Hook::ViewListener
  render_on :view_issues_form_details_bottom, :partial => "youroom/post_to_youroom" 
  render_on :view_issues_edit_notes_bottom, :partial => "youroom/post_to_youroom" 
end
