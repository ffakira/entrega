class ProductCategory < ApplicationRecord
  has_many :products,
           dependent: :restrict_with_exception

  before_validation :normalize_name

  validates :name,
            presence: true,
            length: { maximum: 60 },
            uniqueness: { case_sensitive: false }

  validates :sort_order,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0
            }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:sort_order, :name) }

  private

  def normalize_name
    self.name = name.to_s.squish.capitalize.presence
  end
end
