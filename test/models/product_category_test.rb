require "test_helper"

class ProductCategoryTest < ActiveSupport::TestCase
  test "normalizes category name whitespace and capitalization" do
    category = ProductCategory.create!(name: "  pratos   principais ")

    assert_equal "Pratos principais", category.name
  end

  test "preserves Portuguese accents" do
    category = ProductCategory.create!(name: "  porções especiais ")

    assert_equal "Porções especiais", category.name
  end

  test "rejects a blank name" do
    category = ProductCategory.new(name: "   ")

    assert_not category.valid?
    assert_includes category.errors.attribute_names, :name
  end

  test "rejects duplicate names regardless of capitalization" do
    ProductCategory.create!(name: "Entradas")

    duplicate = ProductCategory.new(name: "entradas")

    assert_not duplicate.valid?
    assert_includes duplicate.errors.attribute_names, :name
  end

  test "requires a non-negative integer sort order" do
    category = ProductCategory.new(name: "Entradas", sort_order: -1)

    assert_not category.valid?
    assert_includes category.errors.attribute_names, :sort_order
  end

  test "cannot be deleted while products reference it" do
    category = product_category

    Product.create!(
      name: "Gyoza",
      product_category: category,
      price_cents: 2500
    )

    assert_raises(ActiveRecord::DeleteRestrictionError) do
      category.destroy!
    end
  end
end
