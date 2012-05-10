class CreateProjectRooms < ActiveRecord::Migration
  def self.up
    create_table :project_rooms do |t|
      t.column :project_id, :integer
      t.column :room_num, :integer
    end
  end

  def self.down
    drop_table :project_rooms
  end
end
