class AddDisplayFieldsToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :color, :string,
               null: false,
               default: "#E7E5E4"

    add_column :products, :glyph, :string,
               null: false,
               default: "•"

    add_column :products, :is_popular, :boolean,
               null: false,
               default: false
  end
end
