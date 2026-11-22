require "test_helper"

module Orders
  class CreateTest < ActiveSupport::TestCase
    def create_product(name: "Gyoza", price_cents: 2500, active: true)
      Product.create!(
        name: name,
        product_category_id: product_category("Appetizer").id,
        price_cents: price_cents,
        active: active
      )
    end

    def valid_input(overrides = {})
      product = create_product

      {
        customer_name: "Akira",
        whatsapp: "(48) 99999-0000",
        fulfilment_type: "pickup",
        payment_timing: "prepaid",
        items: [
          {
            product_id: product.id,
            quantity: 2,
            notes: "Sem cebolinha"
          }
        ]
      }.deep_merge(overrides)
    end

    test "creates a prepaid pickup order" do
      order = Orders::Create.call(valid_input)

      assert_predicate order, :persisted?
      assert_equal "awaiting_payment", order.status
      assert_equal "pending", order.payment_status
      assert_equal "pickup", order.fulfilment_type
      assert_equal "prepaid", order.payment_timing

      assert_equal 5000, order.subtotal_cents
      assert_equal 5000, order.total_cents

      assert_match(/\A\d{8}-0001\z/, order.order_number)

      assert_equal "5548999990000", order.customer.whatsapp
      assert_equal "Akira", order.customer.name

      assert_equal 1, order.order_items.count
      assert_equal "Gyoza", order.order_items.first.product_name
      assert_equal 2500, order.order_items.first.unit_price_cents
      assert_equal 2, order.order_items.first.quantity
      assert_equal 5000, order.order_items.first.line_total_cents
      assert_equal "Sem cebolinha", order.order_items.first.notes

      assert_equal 1, order.order_events.count
      assert_equal "order_created", order.order_events.first.event_type
    end

    test "creates an order payable on handover" do
      order = Orders::Create.call(
        valid_input(payment_timing: "on_handover")
      )

      assert_equal "received", order.status
      assert_equal "on_handover", order.payment_timing
    end

    test "uses current database prices instead of submitted prices" do
      product = create_product(price_cents: 3200)

      input = valid_input(
        items: [
          {
            product_id: product.id,
            quantity: 3,
            unit_price_cents: 1,
            price: 0
          }
        ]
      )

      order = Orders::Create.call(input)

      assert_equal 9600, order.subtotal_cents
      assert_equal 9600, order.total_cents
      assert_equal 3200, order.order_items.first.unit_price_cents
    end

    test "creates a delivery order and saves its address" do
      order = Orders::Create.call(
        valid_input(
          fulfilment_type: "delivery",
          delivery_address: "Rua das Flores, 100",
          delivery_complement: "Apartamento 2",
          delivery_reference: "Próximo à praça"
        )
      )

      assert_equal "delivery", order.fulfilment_type
      assert_equal "Rua das Flores, 100", order.delivery_address

      address = order.customer.customer_addresses.sole

      assert_equal "Apartamento 2", address.complement
      assert_equal "Próximo à praça", address.reference
    end

    test "does not duplicate an existing customer address" do
      input = valid_input(
        fulfilment_type: "delivery",
        delivery_address: "Rua das Flores, 100"
      )

      first_order = Orders::Create.call(input)
      second_order = Orders::Create.call(
        input.merge(items: input[:items])
      )

      assert_equal first_order.customer_id, second_order.customer_id
      assert_equal 1, first_order.customer.customer_addresses.count
    end

    test "reuses existing customers and updates their name" do
      first_order = Orders::Create.call(valid_input(customer_name: "First Name"))

      second_order = Orders::Create.call(
        valid_input(
          customer_name: "Updated Name",
          whatsapp: "5548999990000"
        )
      )

      assert_equal first_order.customer_id, second_order.customer_id
      assert_equal "Updated Name", first_order.customer.reload.name
    end

    test "creates separate sequential order numbers for the same day" do
      first = Orders::Create.call(valid_input)
      second = Orders::Create.call(valid_input)

      date_prefix = Time.current
        .in_time_zone("America/Sao_Paulo")
        .strftime("%Y%m%d")

      assert_equal "#{date_prefix}-0001", first.order_number
      assert_equal "#{date_prefix}-0002", second.order_number
    end

    test "rejects an inactive product and rolls back customer creation" do
      product = create_product(active: false)

      input = {
        whatsapp: "48999990000",
        fulfilment_type: "pickup",
        payment_timing: "prepaid",
        items: [ { product_id: product.id, quantity: 1 } ]
      }

      assert_raises(Orders::Create::InvalidInput) do
        Orders::Create.call(input)
      end

      assert_equal 0, Customer.count
      assert_equal 0, Order.count
      assert_equal 0, OrderItem.count
      assert_equal 0, OrderEvent.count
    end

    test "rejects a nonexistent product" do
      assert_raises(Orders::Create::InvalidInput) do
        Orders::Create.call(
          valid_input(
            items: [ { product_id: 999_999, quantity: 1 } ]
          )
        )
      end
    end

    test "rejects an empty cart" do
      assert_raises(Orders::Create::InvalidInput) do
        Orders::Create.call(valid_input(items: []))
      end
    end

    test "rejects invalid WhatsApp numbers" do
      assert_raises(Orders::Create::InvalidInput) do
        Orders::Create.call(valid_input(whatsapp: "123"))
      end
    end

    test "rejects invalid fulfilment types" do
      assert_raises(Orders::Create::InvalidInput) do
        Orders::Create.call(valid_input(fulfilment_type: "dine_in"))
      end
    end

    test "requires an address for delivery" do
      assert_raises(Orders::Create::InvalidInput) do
        Orders::Create.call(
          valid_input(
            fulfilment_type: "delivery",
            delivery_address: ""
          )
        )
      end
    end

    test "rejects quantities above 999" do
      product = create_product

      assert_raises(Orders::Create::InvalidInput) do
        Orders::Create.call(
          valid_input(
            items: [ { product_id: product.id, quantity: 1000 } ]
          )
        )
      end
    end

    test "rejects oversized item notes" do
      product = create_product

      assert_raises(Orders::Create::InvalidInput) do
        Orders::Create.call(
          valid_input(
            items: [ {
              product_id: product.id,
              quantity: 1,
              notes: "x" * 501
            } ]
          )
        )
      end
    end

    test "rejects invalid payment timing" do
      assert_raises(Orders::Create::InvalidInput) do
        Orders::Create.call(valid_input(payment_timing: "later"))
      end
    end
  end
end
