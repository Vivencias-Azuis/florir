class CreateFamilyAccesses < ActiveRecord::Migration[8.1]
  def change
    create_table :family_accesses do |t|
      t.references :patient, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :relation, null: false
      t.string :access_token, index: { unique: true }
      t.boolean :active, null: false

      t.timestamps
    end
  end
end
