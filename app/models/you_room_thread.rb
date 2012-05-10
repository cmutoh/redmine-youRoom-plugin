class YouRoomThread < ActiveRecord::Base
  unloadable
  belongs_to :issue
end
