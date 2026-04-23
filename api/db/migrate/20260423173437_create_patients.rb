class CreatePatients < ActiveRecord::Migration[8.1]
  def change
    create_table :patients do |t|
      t.references :clinic, null: false, foreign_key: true
      t.string :name
      t.date :birth_date
      t.date :diagnosis_date
      t.integer :diagnosis_level
      t.string :communication_method
      t.text :notes

      t.timestamps
    end
  end
end
