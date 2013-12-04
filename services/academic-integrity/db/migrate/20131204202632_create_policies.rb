class CreatePolicies < ActiveRecord::Migration
  def change
    create_table :policies do |t|
      t.string :title
      t.string :text
      t.string :creator_id
      t.string :creator_course_id
      t.string :creator_course_label

      t.timestamps
    end
  end
end
