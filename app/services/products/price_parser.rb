module Products
  class PriceParser
    def self.call(value)
      new(value).call
    end

    def initialize(value)
      @value = value.to_s.strip
    end

    def call
      return nil if @value.empty?

      normalized = normalize

      return nil unless normalized

      whole, fraction = normalized.split(".", 2)
      fraction = fraction.to_s.ljust(2, "0")

      cents = Integer(whole, 10) * 100 + Integer(fraction, 10)

      return nil if cents > 9_223_372_036_854_775_807

      cents
    rescue ArgumentError, TypeError
      nil
    end

    private

    def normalize
      if @value.include?(",")
        return nil unless @value.match?(
          /\A(?:\d+|\d{1,3}(?:\.\d{3})+),\d{1,2}\z/
        )

        @value.delete(".").tr(",", ".")
      else
        return nil unless @value.match?(/\A\d+(?:\.\d{1,2})?\z/)

        @value
      end
    end
  end
end
