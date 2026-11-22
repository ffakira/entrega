require "test_helper"

class ProductTest < ActiveSupport::TestCase
  test "requires a product category" do
    product = Product.new(
      name: "Gyoza",
      price_cents: 2500
    )

    assert_not product.valid?
    assert_includes product.errors.attribute_names, :product_category
  end

  test "belongs to a product category" do
    category = product_category

    product = Product.create!(
      name: "Gyoza",
      product_category: category,
      price_cents: 2500
    )

    assert_equal category, product.product_category
    assert_includes category.products, product
  end

  test "rejects images larger than 5 MB" do
    product = Product.new(
      name: "Gyoza",
      product_category: product_category,
      price_cents: 2500
    )

    image_data = "\x89PNG\r\n\x1A\n".b + ("x" * (5.megabytes + 1))

    product.image.attach(
      io: StringIO.new(image_data),
      filename: "large.png",
      content_type: "image/png"
    )

    assert_not product.valid?
    assert_includes product.errors[:image], "deve ter no máximo 5 MB"
  end
end
