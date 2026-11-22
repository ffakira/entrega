module Orders
  class Create
    class InvalidInput < StandardError; end

    def self.call(input)
      new(input).call
    end

    def initialize(input)
      @input = input
    end

    def call
      data = validate_input!

      Order.transaction do
        customer = find_or_create_customer(data)

        save_delivery_address(customer, data) if data[:fulfilment_type] == "delivery"

        items, subtotal_cents = build_order_items(data)

        delivery_fee_cents = 0
        discount_cents = 0

        total_cents = subtotal_cents + delivery_fee_cents - discount_cents

        status = data[:payment_timing] == "prepaid" \
          ? "awaiting_payment" \
          : "received"

        order = Order.create!(
          order_number: generate_order_number,
          customer: customer,
          status: status,
          payment_status: "pending",
          fulfilment_type: data[:fulfilment_type],
          payment_timing: data[:payment_timing],
          delivery_address: data[:delivery_address],
          delivery_complement: data[:delivery_complement],
          delivery_reference: data[:delivery_reference],
          delivery_instructions: data[:delivery_instructions],
          subtotal_cents: subtotal_cents,
          delivery_fee_cents: delivery_fee_cents,
          discount_cents: discount_cents,
          total_cents: total_cents,
          notes: data[:notes]
        )

        items.each do |item|
          order.order_items.create!(item)
        end

        order.order_events.create!(
          event_type: "order_created",
          description: "Pedido criado pelo PDV."
        )

        order
      end
    end

    private

    def validate_input!
      unless @input.is_a?(Hash) || @input.respond_to?(:to_unsafe_h)
        raise InvalidInput, "Dados do pedido inválidos."
      end

      input = if @input.respond_to?(:to_unsafe_h)
        @input.to_unsafe_h
      else
        @input
      end

      input = input.with_indifferent_access

      customer_name = input[:customer_name].to_s.strip

      if customer_name.length > 120
        raise InvalidInput, "O nome do cliente deve ter no máximo 120 caracteres."
      end

      whatsapp = normalise_whatsapp(input[:whatsapp])

      fulfilment_type = input[:fulfilment_type].to_s
      payment_timing = input[:payment_timing].to_s

      unless %w[pickup delivery].include?(fulfilment_type)
        raise InvalidInput, "Selecione retirada ou entrega."
      end

      unless %w[prepaid on_handover].include?(payment_timing)
        raise InvalidInput, "Selecione quando o pagamento será realizado."
      end

      delivery_address = input[:delivery_address].to_s.strip

      if fulfilment_type == "delivery" && delivery_address.empty?
        raise InvalidInput, "Informe o endereço de entrega."
      end

      items = input[:items]

      unless items.is_a?(Array) && items.any?
        raise InvalidInput, "Adicione pelo menos um produto ao pedido."
      end

      validated_items = items.map do |item|
        unless item.is_a?(Hash) || item.respond_to?(:to_unsafe_h)
          raise InvalidInput, "Item de pedido inválido."
        end

        item = if item.respond_to?(:to_unsafe_h)
          item.to_unsafe_h
        else
          item
        end

        item = item.with_indifferent_access

        product_id = parse_integer(item[:product_id])
        quantity = parse_integer(item[:quantity])
        notes = item[:notes].to_s.strip

        unless product_id && product_id.positive?
          raise InvalidInput, "Identificador de produto inválido."
        end

        unless quantity && quantity.between?(1, 999)
          raise InvalidInput, "A quantidade deve estar entre 1 e 999."
        end

        if notes.length > 500
          raise InvalidInput, "A observação do item deve ter no máximo 500 caracteres."
        end

        {
          product_id: product_id,
          quantity: quantity,
          notes: notes.presence
        }
      end

      {
        customer_name: customer_name.presence,
        whatsapp: whatsapp,
        fulfilment_type: fulfilment_type,
        payment_timing: payment_timing,
        delivery_address: nullable_string(delivery_address, 255),
        delivery_complement: nullable_string(input[:delivery_complement], 255),
        delivery_reference: nullable_string(input[:delivery_reference], 255),
        delivery_instructions: nullable_string(input[:delivery_instructions], 500),
        notes: nullable_string(input[:notes], 1000),
        items: validated_items
      }
    end

    def normalise_whatsapp(value)
      digits = value.to_s.gsub(/\D/, "")

      if digits.length == 10 || digits.length == 11
        digits = "55#{digits}"
      end

      unless digits.length.between?(10, 15) && !digits.start_with?("0")
        raise InvalidInput,
              "Informe um número de WhatsApp válido com código do país."
      end

      digits
    end

    def parse_integer(value)
      case value
      when Integer
        value
      when String
        return nil unless value.match?(/\A\d+\z/)

        Integer(value, 10)
      else
        nil
      end
    rescue ArgumentError, TypeError
      nil
    end

    def nullable_string(value, max_length)
      result = value.to_s.strip

      if result.length > max_length
        raise InvalidInput, "O campo deve ter no máximo #{max_length} caracteres."
      end

      result.presence
    end

    def find_or_create_customer(data)
      customer = Customer.find_or_initialize_by(
        whatsapp: data[:whatsapp]
      )

      if data[:customer_name].present?
        customer.name = data[:customer_name]
      end

      customer.save!
      customer
    rescue ActiveRecord::RecordNotUnique
      retry
    end

    def save_delivery_address(customer, data)
      customer.customer_addresses.find_or_create_by!(
        address: data[:delivery_address],
        complement: data[:delivery_complement],
        reference: data[:delivery_reference]
      )
    end

    def build_order_items(data)
      subtotal_cents = 0

      items = data[:items].map do |item|
        product = Product.available.find_by(id: item[:product_id])

        unless product
          raise InvalidInput,
                "O produto ##{item[:product_id]} não existe ou está inativo."
        end

        unit_price_cents = product.price_cents
        line_total_cents = unit_price_cents * item[:quantity]

        subtotal_cents += line_total_cents

        {
          product: product,
          product_name: product.name,
          unit_price_cents: unit_price_cents,
          quantity: item[:quantity],
          line_total_cents: line_total_cents,
          notes: item[:notes]
        }
      end

      [ items, subtotal_cents ]
    end

    def generate_order_number
      date_prefix = Time.current
        .in_time_zone("America/Sao_Paulo")
        .strftime("%Y%m%d")

      connection = Order.connection
      quoted_date = connection.quote(date_prefix)

      # SQLite UPSERT atomically allocates the next daily number.
      # The unique date index and the surrounding order transaction
      # prevent two successful requests from receiving the same number.
      last_number = connection.select_value(<<~SQL)
        INSERT INTO order_number_sequences (date, last_number)
        VALUES (#{quoted_date}, 1)
        ON CONFLICT(date)
        DO UPDATE SET last_number = last_number + 1
        RETURNING last_number
      SQL

      "#{date_prefix}-#{format('%04d', last_number.to_i)}"
    end
  end
end
