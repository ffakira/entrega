class Product < ApplicationRecord
  has_many :order_items,
           dependent: :restrict_with_exception

  has_many :orders, through: :order_items

  validates :name,
            presence: true,
            length: { maximum: 120 }

  validates :description,
            length: { maximum: 1000 }

  validates :category,
            presence: true,
            length: { maximum: 60 }

  validates :price_cents,
            numericality: {
              only_integer: true,
              greater_than: 0
            }

  validates :sort_order,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0
            }

  scope :available, -> { where(active: true) }
  scope :ordered, -> { order(:sort_order, :name) }
end
