class CreateCourses < ActiveRecord::Migration
  def change
    create_table :courses do |t|
      t.string :context_id
      t.string :context_label
      t.string :context_title

      t.timestamps
    end
  end
end
