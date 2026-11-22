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
end
