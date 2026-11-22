# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_22_175606) do
  create_table "customer_addresses", force: :cascade do |t|
    t.integer "customer_id", null: false
    t.text "address", null: false
    t.text "complement"
    t.text "reference"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["customer_id"], name: "index_customer_addresses_on_customer_id"
  end

  create_table "customers", force: :cascade do |t|
    t.string "name"
    t.string "whatsapp", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["whatsapp"], name: "index_customers_on_whatsapp", unique: true
  end

  create_table "order_events", force: :cascade do |t|
    t.integer "order_id", null: false
    t.string "event_type", null: false
    t.text "description", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["order_id", "created_at"], name: "index_order_events_on_order_id_and_created_at"
    t.index ["order_id"], name: "index_order_events_on_order_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.integer "order_id", null: false
    t.integer "product_id", null: false
    t.string "product_name", null: false
    t.integer "unit_price_cents", null: false
    t.integer "quantity", null: false
    t.integer "line_total_cents", null: false
    t.text "notes"
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
    t.check_constraint "line_total_cents = unit_price_cents * quantity", name: "order_items_line_total_consistency"
    t.check_constraint "line_total_cents >= 0", name: "order_items_nonnegative_line_total"
    t.check_constraint "quantity > 0", name: "order_items_positive_quantity"
    t.check_constraint "unit_price_cents >= 0", name: "order_items_nonnegative_unit_price"
  end

  create_table "order_number_sequences", force: :cascade do |t|
    t.string "date", null: false
    t.integer "last_number", default: 0, null: false
    t.index ["date"], name: "index_order_number_sequences_on_date", unique: true
    t.check_constraint "last_number >= 0", name: "order_number_sequences_nonnegative"
  end

  create_table "orders", force: :cascade do |t|
    t.string "order_number", null: false
    t.integer "customer_id", null: false
    t.string "status", default: "received", null: false
    t.string "payment_status", default: "pending", null: false
    t.string "fulfilment_type", null: false
    t.string "payment_timing", null: false
    t.text "delivery_address"
    t.text "delivery_complement"
    t.text "delivery_reference"
    t.text "delivery_instructions"
    t.integer "subtotal_cents", null: false
    t.integer "delivery_fee_cents", default: 0, null: false
    t.integer "discount_cents", default: 0, null: false
    t.integer "total_cents", null: false
    t.text "notes"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["created_at"], name: "index_orders_on_created_at"
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["order_number"], name: "index_orders_on_order_number", unique: true
    t.index ["status", "created_at"], name: "index_orders_on_status_and_created_at"
    t.check_constraint "fulfilment_type != 'delivery' OR delivery_address IS NOT NULL", name: "orders_delivery_address_required"
    t.check_constraint "fulfilment_type IN ('pickup', 'delivery')", name: "orders_valid_fulfilment"
    t.check_constraint "payment_status IN ('pending', 'paid', 'partially_paid', 'refunded')", name: "orders_valid_payment_status"
    t.check_constraint "payment_timing IN ('prepaid', 'on_handover')", name: "orders_valid_payment_timing"
    t.check_constraint "status IN ('received', 'awaiting_payment', 'confirmed', 'preparing', 'ready', 'completed', 'cancelled')", name: "orders_valid_status"
    t.check_constraint "subtotal_cents >= 0 AND delivery_fee_cents >= 0 AND discount_cents >= 0 AND total_cents >= 0", name: "orders_nonnegative_amounts"
    t.check_constraint "total_cents = subtotal_cents + delivery_fee_cents - discount_cents", name: "orders_total_consistency"
  end

  create_table "payments", force: :cascade do |t|
    t.integer "order_id", null: false
    t.string "method", null: false
    t.integer "amount_cents", null: false
    t.string "status", default: "pending", null: false
    t.datetime "paid_at"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["order_id"], name: "index_payments_on_order_id"
    t.check_constraint "amount_cents > 0", name: "payments_positive_amount"
    t.check_constraint "method IN ('pix', 'cash', 'debit_card', 'credit_card')", name: "payments_valid_method"
    t.check_constraint "status IN ('pending', 'paid', 'refunded')", name: "payments_valid_status"
  end

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.text "description", default: "", null: false
    t.string "category", null: false
    t.integer "price_cents", null: false
    t.boolean "active", default: true, null: false
    t.integer "sort_order", default: 0, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "color", default: "#E7E5E4", null: false
    t.string "glyph", default: "•", null: false
    t.boolean "is_popular", default: false, null: false
    t.index ["active", "category"], name: "index_products_on_active_and_category"
    t.check_constraint "active IN (0, 1)", name: "products_active_boolean"
    t.check_constraint "price_cents >= 0", name: "products_price_nonnegative"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "customer_addresses", "customers", on_delete: :restrict
  add_foreign_key "order_events", "orders", on_delete: :cascade
  add_foreign_key "order_items", "orders", on_delete: :cascade
  add_foreign_key "order_items", "products", on_delete: :restrict
  add_foreign_key "orders", "customers", on_delete: :restrict
  add_foreign_key "payments", "orders", on_delete: :restrict
  add_foreign_key "sessions", "users"
end
