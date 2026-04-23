class CreateTherapySessions < ActiveRecord::Migration[8.1]
  def change
    create_table :therapy_sessions do |t|
      t.references :clinic, null: false, foreign_key: true
      t.references :patient, null: false, foreign_key: true
      t.integer :therapist_id
      t.datetime :scheduled_at
      t.integer :duration_minutes
      t.string :status
      t.string :modality
      t.text :session_notes

      t.timestamps
    end
    add_index :therapy_sessions, :therapist_id
  end
end
