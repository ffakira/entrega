class OrderItem < ApplicationRecord
  belongs_to :order, inverse_of: :order_items
  belongs_to :product

  validates :product_name, presence: true

  validates :unit_price_cents,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validates :quantity,
            numericality: { only_integer: true, greater_than: 0 }

  validates :line_total_cents,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validate :line_total_matches_quantity

  private

  def line_total_matches_quantity
    return if unit_price_cents.nil? || quantity.nil? || line_total_cents.nil?
    return unless quantity.positive?

    expected_total = unit_price_cents * quantity

    if line_total_cents != expected_total
      errors.add(:line_total_cents, "does not match unit price multiplied by quantity")
    end
  end
end
