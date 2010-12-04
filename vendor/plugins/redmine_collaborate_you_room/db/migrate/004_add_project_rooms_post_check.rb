class AddProjectRoomsPostCheck < ActiveRecord::Migration
  def self.up
    add_column :project_rooms, :post_check, :boolean, :default => false
  end 

  def self.down
    remove_column :project_rooms, :post_check
  end 
end
