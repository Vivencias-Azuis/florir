class CreateTherapeuticGoals < ActiveRecord::Migration[8.1]
  def change
    create_table :therapeutic_goals do |t|
      t.references :clinic, null: false, foreign_key: true
      t.references :patient, null: false, foreign_key: true
      t.string :domain
      t.string :method
      t.string :title
      t.text :description
      t.text :target
      t.string :status
      t.date :started_at
      t.date :achieved_at

      t.timestamps
    end
  end
end
