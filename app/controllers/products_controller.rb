class ProductsController < ApplicationController
  before_action :set_product, only: %i[edit update status remove_image]

  def index
    @products = Product
      .joins(:product_category)
      .includes(:product_category)
      .order(
        "product_categories.sort_order",
        "product_categories.name",
        "products.sort_order",
        "products.name"
      )
  end

  def new
    @product = Product.new
    @price = ""
    load_product_categories
  end

  def create
    @product = Product.new

    assign_product_attributes
    load_product_categories

    if @product.save
      redirect_to products_path, notice: "Produto criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @price = format(
      "%.2f",
      @product.price_cents / 100.0
    ).tr(".", ",")

    load_product_categories
  end

  def update
    assign_product_attributes
    load_product_categories

    if @product.save
      redirect_to products_path, notice: "Produto atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def status
    @product.update!(active: !@product.active?)

    message = @product.active? \
      ? "Produto ativado com sucesso." \
      : "Produto desativado com sucesso."

    redirect_to products_path, notice: message
  end

  def remove_image
    @product.image.purge if @product.image.attached?

    redirect_to edit_product_path(@product),
                notice: "Imagem removida com sucesso."
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def load_product_categories
    @product_categories = ProductCategory.active.ordered.to_a

    selected_category = ProductCategory.find_by(
      id: @product.product_category_id
    )

    if @product.product_category_id.present? && selected_category.nil?
      @product.product_category = nil
    end

    if selected_category && !@product_categories.include?(selected_category)
      @product_categories << selected_category
    end
  end

  def product_params
    params.require(:product).permit(
      :name,
      :description,
      :product_category_id,
      :price,
      :sort_order,
      :image
    )
  end

  def assign_product_attributes
    attributes = product_params

    @price = attributes[:price].to_s

    @product.assign_attributes(
      attributes.except(:price)
    )

    @product.price_cents = Products::PriceParser.call(@price)
  end
end
