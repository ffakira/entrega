class Order < ApplicationRecord
  belongs_to :customer

  has_many :order_items,
           dependent: :destroy,
           inverse_of: :order

  has_many :products, through: :order_items

  has_many :payments,
           dependent: :restrict_with_exception

  has_many :order_events,
           dependent: :destroy

  enum :status, {
    received: "received",
    awaiting_payment: "awaiting_payment",
    confirmed: "confirmed",
    preparing: "preparing",
    ready: "ready",
    completed: "completed",
    cancelled: "cancelled"
  }, default: :received

  enum :payment_status, {
    pending: "pending",
    paid: "paid",
    partially_paid: "partially_paid",
    refunded: "refunded"
  }, default: :pending

  enum :fulfilment_type, {
    pickup: "pickup",
    delivery: "delivery"
  }

  enum :payment_timing, {
    prepaid: "prepaid",
    on_handover: "on_handover"
  }

  validates :order_number, presence: true, uniqueness: true

  validates :subtotal_cents,
            :delivery_fee_cents,
            :discount_cents,
            :total_cents,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validate :total_matches_components
  validate :delivery_address_present

  private

  def total_matches_components
    return if [
      subtotal_cents,
      delivery_fee_cents,
      discount_cents,
      total_cents
    ].any?(&:nil?)

    expected_total = subtotal_cents + delivery_fee_cents - discount_cents

    if expected_total != total_cents
      errors.add(:total_cents, "does not match the order amounts")
    end
  end

  def delivery_address_present
    return unless delivery?
    return if delivery_address.present?

    errors.add(:delivery_address, "must be present for delivery orders")
  end
end
