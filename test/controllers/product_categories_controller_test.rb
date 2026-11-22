require "test_helper"

class ProductCategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.take
    @category = ProductCategory.create!(
      name: "Entradas",
      sort_order: 1
    )
  end

  test "requires authentication for category administration" do
    get product_categories_path
    assert_redirected_to new_session_path

    get new_product_category_path
    assert_redirected_to new_session_path

    get edit_product_category_path(@category)
    assert_redirected_to new_session_path

    post product_categories_path, params: {
      product_category: { name: "Donburi", sort_order: 2 }
    }
    assert_redirected_to new_session_path

    patch product_category_path(@category), params: {
      product_category: { name: "Entradas atualizadas", sort_order: 1 }
    }
    assert_redirected_to new_session_path

    patch status_product_category_path(@category)
    assert_redirected_to new_session_path

    delete product_category_path(@category)
    assert_redirected_to new_session_path
  end

  test "lists categories in display order" do
    sign_in_as(@user)

    ProductCategory.create!(
      name: "Donburi",
      sort_order: 2
    )

    get product_categories_path

    assert_response :success
    assert_select "h1", "Categorias"

    first_position = response.body.index("Entradas")
    second_position = response.body.index("Donburi")

    assert_not_nil first_position
    assert_not_nil second_position
    assert_operator first_position, :<, second_position
  end

  test "creates a category and normalizes its name" do
    sign_in_as(@user)

    assert_difference("ProductCategory.count", 1) do
      post product_categories_path, params: {
        product_category: {
          name: "  Donburi  ",
          description: "Pratos servidos em tigela",
          sort_order: "2"
        }
      }
    end

    category = ProductCategory.find_by!(name: "Donburi")

    assert_equal "Pratos servidos em tigela", category.description
    assert_equal 2, category.sort_order
    assert_redirected_to product_categories_path
  end

  test "does not create a category with invalid attributes" do
    sign_in_as(@user)

    assert_no_difference("ProductCategory.count") do
      post product_categories_path, params: {
        product_category: {
          name: "   ",
          sort_order: "-1"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "does not create a category with a duplicate name" do
    sign_in_as(@user)

    assert_no_difference("ProductCategory.count") do
      post product_categories_path, params: {
        product_category: {
          name: "entradas",
          sort_order: "2"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "updates a category" do
    sign_in_as(@user)

    patch product_category_path(@category), params: {
      product_category: {
        name: "Entradas especiais",
        description: "Entradas da casa",
        sort_order: "3"
      }
    }

    assert_redirected_to product_categories_path

    @category.reload

    assert_equal "Entradas especiais", @category.name
    assert_equal "Entradas da casa", @category.description
    assert_equal 3, @category.sort_order
  end

  test "does not update a category with invalid attributes" do
    sign_in_as(@user)

    patch product_category_path(@category), params: {
      product_category: {
        name: "   ",
        sort_order: "-1"
      }
    }

    assert_response :unprocessable_entity
    assert_equal "Entradas", @category.reload.name
  end

  test "toggles category activation" do
    sign_in_as(@user)

    patch status_product_category_path(@category)

    assert_redirected_to product_categories_path
    assert_not @category.reload.active?

    patch status_product_category_path(@category)

    assert @category.reload.active?
  end

  test "deletes a category without products" do
    sign_in_as(@user)

    assert_difference("ProductCategory.count", -1) do
      delete product_category_path(@category)
    end

    assert_redirected_to product_categories_path
    assert_not ProductCategory.exists?(@category.id)
  end

  test "does not delete a category referenced by products" do
    sign_in_as(@user)

    Product.create!(
      name: "Gyoza",
      product_category: @category,
      price_cents: 2500
    )

    assert_no_difference("ProductCategory.count") do
      delete product_category_path(@category)
    end

    assert_redirected_to product_categories_path

    assert_equal(
      "Não é possível remover uma categoria que possui produtos.",
      flash[:alert]
    )

    assert ProductCategory.exists?(@category.id)
  end
end
