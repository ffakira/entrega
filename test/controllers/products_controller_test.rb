require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.take
  end

  test "requires authentication to access product administration" do
    get products_path

    assert_redirected_to new_session_path
  end

  test "lists products for an authenticated user" do
    sign_in_as(@user)

    Product.create!(
      name: "Gyoza",
      category: "Entradas",
      price_cents: 2500
    )

    get products_path

    assert_response :success
    assert_select "h1", "Produtos"
    assert_select "td", "Gyoza"
    assert_select "td", "R$ 25,00"
  end

  test "creates a product using Brazilian currency input" do
    sign_in_as(@user)

    assert_difference("Product.count", 1) do
      post products_path, params: {
        product: {
          name: "Gyoza",
          description: "Porção de seis unidades",
          category: "Entradas",
          price: "32,90",
          sort_order: "1"
        }
      }
    end

    product = Product.order(:id).last

    assert_equal "Gyoza", product.name
    assert_equal 3290, product.price_cents
    assert_equal 1, product.sort_order
    assert_redirected_to products_path
  end

  test "does not create a product with an invalid price" do
    sign_in_as(@user)

    assert_no_difference("Product.count") do
      post products_path, params: {
        product: {
          name: "Gyoza",
          category: "Entradas",
          price: "invalid",
          sort_order: "0"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "updates an existing product" do
    sign_in_as(@user)

    product = Product.create!(
      name: "Gyoza",
      category: "Entradas",
      price_cents: 2500
    )

    patch product_path(product), params: {
      product: {
        name: "Gyoza especial",
        category: "Entradas",
        price: "35,90",
        sort_order: "2"
      }
    }

    assert_redirected_to products_path

    product.reload

    assert_equal "Gyoza especial", product.name
    assert_equal 3590, product.price_cents
    assert_equal 2, product.sort_order
  end

  test "toggles product availability" do
    sign_in_as(@user)

    product = Product.create!(
      name: "Gyoza",
      category: "Entradas",
      price_cents: 2500,
      active: true
    )

    patch status_product_path(product)

    assert_redirected_to products_path
    assert_not product.reload.active?

    patch status_product_path(product)

    assert product.reload.active?
  end

  test "does not expose product administration to unauthenticated users" do
    product = Product.create!(
      name: "Gyoza",
      category: "Entradas",
      price_cents: 2500
    )

    get new_product_path
    assert_redirected_to new_session_path

    get edit_product_path(product)
    assert_redirected_to new_session_path

    patch status_product_path(product)
    assert_redirected_to new_session_path
  end
end

class ProductsControllerImageTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.take
    sign_in_as(@user)
  end

  test "creates a product with an image" do
    assert_difference("Product.count", 1) do
      post products_path, params: {
        product: {
          name: "Gyoza",
          category: "Entradas",
          price: "32,90",
          sort_order: "0",
          image: fixture_file_upload(
            "product.png",
            "image/png"
          )
        }
      }
    end

    product = Product.order(:id).last

    assert product.image.attached?
    assert_equal "product.png", product.image.filename.to_s
    assert_redirected_to products_path
  end

  test "rejects an unsupported image format" do
    assert_no_difference("Product.count") do
      post products_path, params: {
        product: {
          name: "Gyoza",
          category: "Entradas",
          price: "32,90",
          sort_order: "0",
          image: fixture_file_upload(
            "not_an_image.txt",
            "text/plain"
          )
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "li", text: /JPEG, PNG ou WebP/
  end

  test "preserves the existing image when replacement is invalid" do
    product = Product.create!(
      name: "Gyoza",
      category: "Entradas",
      price_cents: 2500
    )

    product.image.attach(
      fixture_file_upload("product.png", "image/png")
    )

    original_blob_id = product.image.blob.id

    patch product_path(product), params: {
      product: {
        name: "Gyoza atualizado",
        category: "Entradas",
        price: "35,90",
        sort_order: "0",
        image: fixture_file_upload(
          "not_an_image.txt",
          "text/plain"
        )
      }
    }

    assert_response :unprocessable_entity

    product.reload

    assert_equal original_blob_id, product.image.blob.id
    assert_equal "Gyoza", product.name
  end

  test "renders the product image in the administration list" do
    product = Product.create!(
      name: "Gyoza",
      category: "Entradas",
      price_cents: 2500
    )

    product.image.attach(
      fixture_file_upload("product.png", "image/png")
    )

    get products_path

    assert_response :success
    assert_select "img[alt='Gyoza']"
  end
end
