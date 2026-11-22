class ProductsController < ApplicationController
  before_action :set_product, only: %i[edit update status]

  def index
    @products = Product.order(:category, :sort_order, :name)
  end

  def new
    @product = Product.new
    @price = ""
  end

  def create
    @product = Product.new

    assign_product_attributes

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
  end

  def update
    assign_product_attributes

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

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.require(:product).permit(
      :name,
      :description,
      :category,
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
