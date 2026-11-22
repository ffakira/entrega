require "test_helper"

class ProductTest < ActiveSupport::TestCase
  test "rejects images larger than 5 MB" do
    product = Product.new(
      name: "Gyoza",
      category: "Entradas",
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

  test "normalizes category whitespace and capitalization" do
    product = Product.new(
      name: "Gyoza",
      category: "  pratos   principais ",
      price_cents: 2500
    )

    assert product.valid?
    assert_equal "Pratos principais", product.category
  end

  test "normalizes a single-word category" do
    product = Product.new(
      name: "Gyoza",
      category: "  gyoza  ",
      price_cents: 2500
    )

    assert product.valid?
    assert_equal "Gyoza", product.category
  end

  test "rejects a blank category" do
    product = Product.new(
      name: "Gyoza",
      category: "   ",
      price_cents: 2500
    )

    assert_not product.valid?
    category_errors = product.errors.details[:category].map do |error|
      error[:error]
    end

    assert_includes category_errors, :blank
  end

  test "preserves Portuguese accents when normalizing category" do
    product = Product.new(
      name: "Gyoza",
      category: "  porções especiais ",
      price_cents: 2500
    )

    assert product.valid?
    assert_equal "Porções especiais", product.category
  end
end
