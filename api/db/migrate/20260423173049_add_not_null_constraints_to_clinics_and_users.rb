class AddNotNullConstraintsToClinicsAndUsers < ActiveRecord::Migration[8.1]
  def change
    change_column_null :clinics, :name, false
    change_column_null :clinics, :slug, false
    change_column_null :clinics, :email, false
    change_column_null :users, :name, false
    change_column_null :users, :email, false
    change_column_null :users, :role, false
    change_column_null :users, :password_digest, false
  end
end
