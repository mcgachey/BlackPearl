class AddPolicyIdToCourse < ActiveRecord::Migration
  def change
    add_column :courses, :policy_id, :int
  end
end
