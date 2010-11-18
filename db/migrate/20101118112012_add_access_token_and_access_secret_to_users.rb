class AddAccessTokenAndAccessSecretToUsers < ActiveRecord::Migration
  def self.up
    add_column(:users,:access_token,:default=>'')
    add_column(:users,:access_secret,:default=>'')
  end

  def self.down
    remove_column(:users,:access_token)
    remove_column(:users,:access_secret)
  end
end
