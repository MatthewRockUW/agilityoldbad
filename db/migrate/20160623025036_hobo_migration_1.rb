class HoboMigration1 < ActiveRecord::Migration
  def self.up
    change_column :projects, :stories_count, :integer, :null => false, :default => 0

    change_column :stories, :tasks_count, :integer, :null => false, :default => 0

    change_column :users, :administrator, :boolean, :default => false
  end

  def self.down
    change_column :projects, :stories_count, :integer, default: 0, null: false

    change_column :stories, :tasks_count, :integer, default: 0, null: false

    change_column :users, :administrator, :boolean, default: false
  end
end
