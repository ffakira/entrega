class CreatePosDomain < ActiveRecord::Migration[8.1]
  def change
    create_table :customers do |t|
      t.string :name
      t.string :whatsapp, null: false
      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :customers, :whatsapp, unique: true

    create_table :customer_addresses do |t|
      t.references :customer,
                   null: false,
                   foreign_key: { on_delete: :restrict }

      t.text :address, null: false
      t.text :complement
      t.text :reference
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    create_table :products do |t|
      t.string :name, null: false
      t.text :description, null: false, default: ""
      t.string :category, null: false
      t.integer :price_cents, null: false
      t.boolean :active, null: false, default: true
      t.integer :sort_order, null: false, default: 0
      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_check_constraint :products,
                         "price_cents >= 0",
                         name: "products_price_nonnegative"

    add_check_constraint :products,
                         "active IN (0, 1)",
                         name: "products_active_boolean"

    add_index :products, [:active, :category]

    create_table :orders do |t|
      t.string :order_number, null: false
      t.references :customer,
                   null: false,
                   foreign_key: { on_delete: :restrict }

      t.string :status, null: false, default: "received"
      t.string :payment_status, null: false, default: "pending"
      t.string :fulfilment_type, null: false
      t.string :payment_timing, null: false

      t.text :delivery_address
      t.text :delivery_complement
      t.text :delivery_reference
      t.text :delivery_instructions

      t.integer :subtotal_cents, null: false
      t.integer :delivery_fee_cents, null: false, default: 0
      t.integer :discount_cents, null: false, default: 0
      t.integer :total_cents, null: false

      t.text :notes
      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :orders, :order_number, unique: true
    add_index :orders, [:status, :created_at]
    add_index :orders, :created_at

    add_check_constraint :orders,
                         "status IN ('received', 'awaiting_payment', 'confirmed', 'preparing', 'ready', 'completed', 'cancelled')",
                         name: "orders_valid_status"

    add_check_constraint :orders,
                         "payment_status IN ('pending', 'paid', 'partially_paid', 'refunded')",
                         name: "orders_valid_payment_status"

    add_check_constraint :orders,
                         "fulfilment_type IN ('pickup', 'delivery')",
                         name: "orders_valid_fulfilment"

    add_check_constraint :orders,
                         "payment_timing IN ('prepaid', 'on_handover')",
                         name: "orders_valid_payment_timing"

    add_check_constraint :orders,
                         "subtotal_cents >= 0 AND delivery_fee_cents >= 0 AND discount_cents >= 0 AND total_cents >= 0",
                         name: "orders_nonnegative_amounts"

    add_check_constraint :orders,
                         "total_cents = subtotal_cents + delivery_fee_cents - discount_cents",
                         name: "orders_total_consistency"

    add_check_constraint :orders,
                         "fulfilment_type != 'delivery' OR delivery_address IS NOT NULL",
                         name: "orders_delivery_address_required"

    create_table :order_items do |t|
      t.references :order,
                   null: false,
                   foreign_key: { on_delete: :cascade }

      t.references :product,
                   null: false,
                   foreign_key: { on_delete: :restrict }

      t.string :product_name, null: false
      t.integer :unit_price_cents, null: false
      t.integer :quantity, null: false
      t.integer :line_total_cents, null: false
      t.text :notes
    end

    add_check_constraint :order_items,
                         "unit_price_cents >= 0",
                         name: "order_items_nonnegative_unit_price"

    add_check_constraint :order_items,
                         "quantity > 0",
                         name: "order_items_positive_quantity"

    add_check_constraint :order_items,
                         "line_total_cents >= 0",
                         name: "order_items_nonnegative_line_total"

    add_check_constraint :order_items,
                         "line_total_cents = unit_price_cents * quantity",
                         name: "order_items_line_total_consistency"

    create_table :payments do |t|
      t.references :order,
                   null: false,
                   foreign_key: { on_delete: :restrict }

      t.string :method, null: false
      t.integer :amount_cents, null: false
      t.string :status, null: false, default: "pending"
      t.datetime :paid_at
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    add_check_constraint :payments,
                         "method IN ('pix', 'cash', 'debit_card', 'credit_card')",
                         name: "payments_valid_method"

    add_check_constraint :payments,
                         "amount_cents > 0",
                         name: "payments_positive_amount"

    add_check_constraint :payments,
                         "status IN ('pending', 'paid', 'refunded')",
                         name: "payments_valid_status"

    create_table :order_events do |t|
      t.references :order,
                   null: false,
                   foreign_key: { on_delete: :cascade }

      t.string :event_type, null: false
      t.text :description, null: false
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :order_events, [:order_id, :created_at]
  end
end
