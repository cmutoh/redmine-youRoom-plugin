class ProjectRoom < ActiveRecord::Base
  unloadable
  belongs_to :project
end
