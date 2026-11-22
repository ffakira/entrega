class CreateOrderNumberSequences < ActiveRecord::Migration[8.1]
  def change
    create_table :order_number_sequences do |t|
      t.string :date, null: false
      t.integer :last_number, null: false, default: 0
    end

    add_index :order_number_sequences, :date, unique: true

    add_check_constraint :order_number_sequences,
                         "last_number >= 0",
                         name: "order_number_sequences_nonnegative"
  end
end
