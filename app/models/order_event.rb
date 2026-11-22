class OrderEvent < ApplicationRecord
  belongs_to :order

  validates :event_type, presence: true
  validates :description, presence: true
end
