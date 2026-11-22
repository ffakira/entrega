require "test_helper"

class MenuControllerTest < ActionDispatch::IntegrationTest
  test "shows active products grouped by category" do
    gyoza = create_product(
      name: "Gyoza",
      category: "Entradas",
      price_cents: 2500,
      sort_order: 1
    )

    create_product(
      name: "Karaage",
      category: "Entradas",
      price_cents: 3200,
      sort_order: 2
    )

    create_product(
      name: "Teriyaki Donburi",
      category: "Pratos principais",
      price_cents: 4500
    )

    get menu_path

    assert_response :success
    assert_select "h2", "Entradas"
    assert_select "h2", "Pratos principais"
    assert_select "h3", "Gyoza"
    assert_select "h3", "Karaage"
    assert_select "h3", "Teriyaki Donburi"
    assert_select "p", text: "R$ 25,00"
  end

  test "does not show inactive products" do
    create_product(name: "Hidden product", active: false)

    get menu_path

    assert_response :success
    assert_no_match "Hidden product", response.body
  end

  test "shows an empty state when no active products exist" do
    get menu_path

    assert_response :success
    assert_match "Nosso menu está sendo atualizado", response.body
  end

  private

  def create_product(
    name: "Test product",
    category: "Entradas",
    price_cents: 2500,
    active: true,
    sort_order: 0
  )
    Product.create!(
      name: name,
      category: category,
      price_cents: price_cents,
      active: active,
      sort_order: sort_order
    )
  end
end
