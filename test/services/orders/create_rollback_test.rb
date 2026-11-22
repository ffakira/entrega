require "test_helper"

module Orders
  class CreateRollbackTest < ActiveSupport::TestCase
    test "rolls back the entire order when event creation fails" do
      product = Product.create!(
        name: "Gyoza",
        category: "appetizer",
        price_cents: 2500,
        active: true
      )

      input = {
        customer_name: "Akira",
        whatsapp: "48999990000",
        fulfilment_type: "pickup",
        payment_timing: "prepaid",
        items: [
          {
            product_id: product.id,
            quantity: 2
          }
        ]
      }

      connection = ActiveRecord::Base.connection

      connection.execute(<<~SQL)
        CREATE TEMP TRIGGER fail_order_event_insert
        BEFORE INSERT ON order_events
        BEGIN
          SELECT RAISE(ABORT, 'Forced event creation failure');
        END;
      SQL

      begin
        assert_raises(ActiveRecord::StatementInvalid) do
          Orders::Create.call(input)
        end
      ensure
        connection.execute(
          "DROP TRIGGER IF EXISTS fail_order_event_insert"
        )
      end

      assert_equal 0, Customer.count
      assert_equal 0, Order.count
      assert_equal 0, OrderItem.count
      assert_equal 0, OrderEvent.count
      assert_equal 0, ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM order_number_sequences").to_i
    end
  end
end
