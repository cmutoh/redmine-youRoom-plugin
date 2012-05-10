require 'redmine'
require 'issue_listener'
require 'issues_controller_patch'
require 'issue_hooks'

Redmine::Plugin.register :redmine_collaborate_you_room do
  name 'Redmine Collaborate You Room plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
# url 'http://example.com/path/to/plugin'
# author_url 'http://example.com/about'
  
#  project_module :youroom do
    permission :set_room_number, :youroom => :register
#  end
  menu :project_menu, :set_room_num, { :controller => 'youroom',:action => 'register'}, :caption => 'youRoom',:last => true, :param => :project_id
end
