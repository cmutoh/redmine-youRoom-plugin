class CreateOauthTokens < ActiveRecord::Migration
  def self.up
    create_table :oauth_tokens do |t|
      t.column :user_id, :integer
      t.column :access_token, :string
      t.column :access_secret, :string
    end
  end

  def self.down
    drop_table :oauth_tokens
  end
end
