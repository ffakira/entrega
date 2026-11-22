class CreateProductCategories < ActiveRecord::Migration[8.1]
  def up
    create_table :product_categories do |t|
      t.string :name, null: false
      t.text :description
      t.integer :sort_order, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :product_categories, :name, unique: true

    add_reference :products,
                  :product_category,
                  null: true,
                  foreign_key: { on_delete: :restrict }

    say_with_time "Preserving existing product categories" do
      legacy_categories = connection.select_values(
        "SELECT DISTINCT category FROM products ORDER BY category"
      )

      legacy_categories.each do |legacy_name|
        normalized_name = legacy_name.to_s.squish.capitalize

        if normalized_name.blank?
          raise ActiveRecord::MigrationError,
                "Cannot migrate products with a blank category"
        end

        quoted_name = connection.quote(normalized_name)

        category_id = connection.select_value(
          "SELECT id FROM product_categories WHERE name = #{quoted_name}"
        )

        unless category_id
          now = connection.quote(Time.current)

          execute <<~SQL
            INSERT INTO product_categories
              (name, description, sort_order, active, created_at, updated_at)
            VALUES
              (#{quoted_name}, NULL, 0, 1, #{now}, #{now})
          SQL

          category_id = connection.select_value(
            "SELECT id FROM product_categories WHERE name = #{quoted_name}"
          )
        end

        quoted_legacy_name = connection.quote(legacy_name)

        execute <<~SQL
          UPDATE products
          SET product_category_id = #{connection.quote(category_id)}
          WHERE category = #{quoted_legacy_name}
        SQL
      end
    end

    if select_value("SELECT COUNT(*) FROM products WHERE product_category_id IS NULL").to_i.positive?
      raise ActiveRecord::MigrationError,
            "Some products could not be assigned to a category"
    end

    remove_index :products, name: "index_products_on_active_and_category"

    change_column_null :products, :product_category_id, false
    remove_column :products, :category

    add_index :products, [:active, :product_category_id],
              name: "index_products_on_active_and_product_category"
  end

  def down
    remove_index :products,
                 name: "index_products_on_active_and_product_category"

    add_column :products, :category, :string

    execute <<~SQL
      UPDATE products
      SET category = (
        SELECT product_categories.name
        FROM product_categories
        WHERE product_categories.id = products.product_category_id
      )
    SQL

    change_column_null :products, :category, false

    remove_reference :products, :product_category, foreign_key: true

    add_index :products, [:active, :category]

    drop_table :product_categories
  end
end
