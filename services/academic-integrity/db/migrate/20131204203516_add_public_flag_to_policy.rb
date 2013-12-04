class AddPublicFlagToPolicy < ActiveRecord::Migration
  def change
    add_column :policies, :is_public, :boolean
  end
end
