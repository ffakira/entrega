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
      product_category_id: product_category("Entradas").id,
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
          product_category_id: product_category("Entradas").id,
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
          product_category_id: product_category("Entradas").id,
          price: "invalid",
          sort_order: "0"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "does not create a product with a nonexistent category" do
    sign_in_as(@user)

    assert_no_difference("Product.count") do
      post products_path, params: {
        product: {
          name: "Gyoza",
          product_category_id: 999_999,
          price: "32,90",
          sort_order: "0"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "keeps an inactive category selected when editing its product" do
    sign_in_as(@user)

    category = ProductCategory.create!(
      name: "Categoria antiga",
      active: false
    )

    product = Product.create!(
      name: "Gyoza",
      product_category: category,
      price_cents: 2500
    )

    get edit_product_path(product)

    assert_response :success
    assert_select(
      "select[name='product[product_category_id]'] option[selected][value='#{category.id}']",
      text: "Categoria antiga"
    )
  end

  test "updates an existing product" do
    sign_in_as(@user)

    product = Product.create!(
      name: "Gyoza",
      product_category_id: product_category("Entradas").id,
      price_cents: 2500
    )

    patch product_path(product), params: {
      product: {
        name: "Gyoza especial",
        product_category_id: product_category("Entradas").id,
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
      product_category_id: product_category("Entradas").id,
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
      product_category_id: product_category("Entradas").id,
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
          product_category_id: product_category("Entradas").id,
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
          product_category_id: product_category("Entradas").id,
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
      product_category_id: product_category("Entradas").id,
      price_cents: 2500
    )

    product.image.attach(
      fixture_file_upload("product.png", "image/png")
    )

    original_blob_id = product.image.blob.id

    patch product_path(product), params: {
      product: {
        name: "Gyoza atualizado",
        product_category_id: product_category("Entradas").id,
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
      product_category_id: product_category("Entradas").id,
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


class ProductsControllerImageRemovalTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.take
    @product = Product.create!(
      name: "Gyoza",
      product_category_id: product_category("Entradas").id,
      price_cents: 2500
    )
    @product.image.attach(
      fixture_file_upload("product.png", "image/png")
    )
  end

  test "removes the image without deleting the product" do
    sign_in_as(@user)

    assert_difference("ActiveStorage::Attachment.count", -1) do
      assert_difference("ActiveStorage::Blob.count", -1) do
        assert_no_difference("Product.count") do
          delete remove_image_product_path(@product)
        end
      end
    end

    assert_redirected_to edit_product_path(@product)
    assert_equal "Imagem removida com sucesso.", flash[:notice]
    assert_not @product.reload.image.attached?
    assert_equal "Gyoza", @product.name
  end

  test "requires authentication to remove an image" do
    delete remove_image_product_path(@product)

    assert_redirected_to new_session_path
    assert @product.reload.image.attached?
  end

  test "handles removal when the product has no image" do
    sign_in_as(@user)
    @product.image.purge

    assert_no_difference("Product.count") do
      delete remove_image_product_path(@product)
    end

    assert_redirected_to edit_product_path(@product)
    assert_not @product.reload.image.attached?
  end
end
