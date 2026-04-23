class CreateGoalProgresses < ActiveRecord::Migration[8.1]
  def change
    create_table :goal_progresses do |t|
      t.references :goal, null: false, foreign_key: { to_table: :therapeutic_goals }
      t.references :session, null: false, foreign_key: { to_table: :therapy_sessions }
      t.integer :therapist_id
      t.integer :score
      t.text :notes
      t.datetime :recorded_at

      t.timestamps
    end
  end
end
