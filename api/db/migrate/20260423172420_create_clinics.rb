class CreateClinics < ActiveRecord::Migration[8.1]
  def change
    create_table :clinics do |t|
      t.string :name
      t.string :slug
      t.string :email
      t.string :phone
      t.string :plan

      t.timestamps
    end
    add_index :clinics, :slug, unique: true
  end
end
