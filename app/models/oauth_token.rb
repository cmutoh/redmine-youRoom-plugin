class OauthToken < ActiveRecord::Base
  unloadable
  belongs_to :user
end
