class Customer < ApplicationRecord
  has_many :customer_addresses,
           dependent: :restrict_with_exception

  has_many :orders,
           dependent: :restrict_with_exception

  has_many :addresses,
           class_name: "CustomerAddress",
           dependent: :restrict_with_exception,
           inverse_of: :customer

  validates :whatsapp, presence: true, uniqueness: true
end
