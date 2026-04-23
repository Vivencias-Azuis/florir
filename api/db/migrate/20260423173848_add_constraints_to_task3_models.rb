class AddConstraintsToTask3Models < ActiveRecord::Migration[8.1]
  def change
    # patients
    change_column_null :patients, :name, false

    # therapy_sessions
    change_column_null :therapy_sessions, :scheduled_at, false
    change_column_null :therapy_sessions, :status, false
    change_column_null :therapy_sessions, :therapist_id, false
    add_foreign_key :therapy_sessions, :users, column: :therapist_id

    # therapeutic_goals
    change_column_null :therapeutic_goals, :title, false
    change_column_null :therapeutic_goals, :domain, false
    change_column_null :therapeutic_goals, :status, false

    # goal_progresses
    change_column_null :goal_progresses, :score, false
    change_column_null :goal_progresses, :recorded_at, false
    change_column_null :goal_progresses, :therapist_id, false
    add_foreign_key :goal_progresses, :users, column: :therapist_id
    add_index :goal_progresses, :therapist_id
  end
end
