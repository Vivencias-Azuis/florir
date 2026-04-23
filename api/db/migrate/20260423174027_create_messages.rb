class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :clinic, null: false, foreign_key: true
      t.references :patient, null: false, foreign_key: true
      t.integer :sender_id, null: false
      t.integer :receiver_id, null: false
      t.text :body, null: false
      t.datetime :read_at

      t.timestamps
    end

    add_foreign_key :messages, :users, column: :sender_id
    add_foreign_key :messages, :users, column: :receiver_id
  end
end
