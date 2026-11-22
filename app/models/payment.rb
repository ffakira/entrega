class Payment < ApplicationRecord
  belongs_to :order

  enum :method, {
    pix: "pix",
    cash: "cash",
    debit_card: "debit_card",
    credit_card: "credit_card"
  }

  enum :status, {
    pending: "pending",
    paid: "paid",
    refunded: "refunded"
  }, default: :pending

  validates :amount_cents,
            numericality: { only_integer: true, greater_than: 0 }
end
