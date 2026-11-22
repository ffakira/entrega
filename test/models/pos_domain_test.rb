require "test_helper"

class PosDomainTest < ActiveSupport::TestCase
  def create_customer
    Customer.create!(whatsapp: "48999990000")
  end

  def create_product
    Product.create!(
      name: "Gyoza",
      product_category_id: product_category("Appetizer").id,
      price_cents: 2500
    )
  end

  def create_order(customer: create_customer, **attributes)
    Order.create!({
      order_number: "AK-000001",
      customer: customer,
      fulfilment_type: :pickup,
      payment_timing: :prepaid,
      subtotal_cents: 5000,
      delivery_fee_cents: 0,
      discount_cents: 0,
      total_cents: 5000
    }.merge(attributes))
  end

  test "customer requires a unique WhatsApp number" do
    customer = create_customer

    duplicate = Customer.new(whatsapp: customer.whatsapp)

    assert_not duplicate.valid?
    assert_includes duplicate.errors.attribute_names, :whatsapp
  end

  test "customer owns addresses and orders" do
    customer = create_customer

    address = customer.customer_addresses.create!(
      address: "Rua das Flores, 100"
    )

    order = create_order(customer: customer)

    assert_equal customer, address.customer
    assert_equal customer, order.customer
    assert_includes customer.customer_addresses, address
    assert_includes customer.orders, order
  end

  test "product price cannot be negative" do
    product = Product.new(
      name: "Gyoza",
      product_category_id: product_category("Appetizer").id,
      price_cents: -100
    )

    assert_not product.valid?
    assert_includes product.errors.attribute_names, :price_cents
  end

  test "product availability scope returns only active products" do
    active = create_product
    inactive = Product.create!(
      name: "Unavailable",
      product_category_id: product_category("Other").id,
      price_cents: 1000,
      active: false
    )

    assert_includes Product.available, active
    assert_not_includes Product.available, inactive
  end

  test "order defaults to received and pending payment" do
    order = create_order

    assert_equal "received", order.status
    assert_equal "pending", order.payment_status
  end

  test "order total must match subtotal, delivery fee and discount" do
    order = Order.new(
      customer: create_customer,
      order_number: "AK-000002",
      fulfilment_type: :pickup,
      payment_timing: :prepaid,
      subtotal_cents: 5000,
      delivery_fee_cents: 1000,
      discount_cents: 500,
      total_cents: 6000
    )

    assert_not order.valid?
    assert_includes order.errors.attribute_names, :total_cents
  end

  test "delivery order requires an address" do
    order = Order.new(
      customer: create_customer,
      order_number: "AK-000003",
      fulfilment_type: :delivery,
      payment_timing: :prepaid,
      subtotal_cents: 5000,
      delivery_fee_cents: 500,
      discount_cents: 0,
      total_cents: 5500
    )

    assert_not order.valid?
    assert_includes order.errors.attribute_names, :delivery_address
  end

  test "delivery order accepts an address" do
    order = create_order(
      order_number: "AK-000004",
      fulfilment_type: :delivery,
      delivery_address: "Rua das Flores, 100",
      delivery_fee_cents: 500,
      total_cents: 5500
    )

    assert_predicate order, :valid?
  end

  test "order item preserves product name and price snapshots" do
    product = create_product
    order = create_order

    item = order.order_items.create!(
      product: product,
      product_name: product.name,
      unit_price_cents: 2500,
      quantity: 2,
      line_total_cents: 5000
    )

    product.update!(name: "Updated Gyoza", price_cents: 3000)

    item.reload

    assert_equal "Gyoza", item.product_name
    assert_equal 2500, item.unit_price_cents
    assert_equal 5000, item.line_total_cents
  end

  test "order item rejects an inconsistent line total" do
    item = OrderItem.new(
      order: create_order,
      product: create_product,
      product_name: "Gyoza",
      unit_price_cents: 2500,
      quantity: 2,
      line_total_cents: 4000
    )

    assert_not item.valid?
    assert_includes item.errors.attribute_names, :line_total_cents
  end

  test "payment requires a positive amount" do
    payment = Payment.new(
      order: create_order,
      method: :pix,
      amount_cents: 0
    )

    assert_not payment.valid?
    assert_includes payment.errors.attribute_names, :amount_cents
  end

  test "payment defaults to pending" do
    payment = Payment.create!(
      order: create_order,
      method: :pix,
      amount_cents: 5000
    )

    assert_equal "pending", payment.status
  end

  test "order event belongs to an order" do
    order = create_order

    event = order.order_events.create!(
      event_type: "status_changed",
      description: "Order received"
    )

    assert_equal order, event.order
  end

  test "database rejects an inconsistent order item total" do
    order = create_order
    product = create_product

    assert_raises(ActiveRecord::StatementInvalid) do
      OrderItem.insert_all!([{
        order_id: order.id,
        product_id: product.id,
        product_name: product.name,
        unit_price_cents: 2500,
        quantity: 2,
        line_total_cents: 4000
      }])
    end
  end

  test "database rejects an order total that does not balance" do
    customer = create_customer

    assert_raises(ActiveRecord::StatementInvalid) do
      Order.insert_all!([{
        order_number: "AK-000099",
        customer_id: customer.id,
        status: "received",
        payment_status: "pending",
        fulfilment_type: "pickup",
        payment_timing: "prepaid",
        subtotal_cents: 5000,
        delivery_fee_cents: 0,
        discount_cents: 0,
        total_cents: 4000
      }])
    end
  end
end
