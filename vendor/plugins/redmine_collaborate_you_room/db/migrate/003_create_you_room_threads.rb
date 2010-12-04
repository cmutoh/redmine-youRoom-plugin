class CreateYouRoomThreads < ActiveRecord::Migration
  def self.up
    create_table :you_room_threads do |t|
      t.column :thread_id, :integer
      t.column :issue_id, :integer
    end
  end

  def self.down
    drop_table :you_room_threads
  end
end
