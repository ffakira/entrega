class Product < ApplicationRecord
  before_validation :normalize_category
  has_many :order_items,
           dependent: :restrict_with_exception

  has_many :orders, through: :order_items

  has_one_attached :image do |attachable|
    attachable.variant :thumbnail,
                       resize_to_limit: [160, 160],
                       format: :webp

    attachable.variant :menu,
                       resize_to_limit: [640, 640],
                       format: :webp
  end

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

  validate :image_is_valid

  scope :available, -> { where(active: true) }
  scope :ordered, -> { order(:sort_order, :name) }

  private

  def normalize_category
    self.category = category.to_s.squish.capitalize.presence
  end

  def image_is_valid
    return unless image.attached?

    unless %w[image/jpeg image/png image/webp].include?(image.blob.content_type)
      errors.add(:image, "deve ser JPEG, PNG ou WebP")
    end

    if image.blob.byte_size > 5.megabytes
      errors.add(:image, "deve ter no máximo 5 MB")
    end
  end
end
