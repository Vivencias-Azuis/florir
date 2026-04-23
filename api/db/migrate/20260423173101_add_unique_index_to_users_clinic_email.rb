class AddUniqueIndexToUsersClinicEmail < ActiveRecord::Migration[8.1]
  def change
    add_index :users, [ :clinic_id, :email ], unique: true
  end
end
