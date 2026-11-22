class ProductCategoriesController < ApplicationController
  before_action :set_product_category, only: %i[edit update status destroy]

  def index
    @product_categories = ProductCategory.ordered
  end

  def new
    @product_category = ProductCategory.new
  end

  def create
    @product_category = ProductCategory.new(product_category_params)

    if @product_category.save
      redirect_to product_categories_path,
                  notice: "Categoria criada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @product_category.update(product_category_params)
      redirect_to product_categories_path,
                  notice: "Categoria atualizada com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def status
    @product_category.update!(active: !@product_category.active?)

    message = @product_category.active? \
      ? "Categoria ativada com sucesso." \
      : "Categoria desativada com sucesso."

    redirect_to product_categories_path, notice: message
  end

  def destroy
    @product_category.destroy!

    redirect_to product_categories_path,
                notice: "Categoria removida com sucesso."
  rescue ActiveRecord::DeleteRestrictionError,
         ActiveRecord::InvalidForeignKey
    redirect_to product_categories_path,
                alert: "Não é possível remover uma categoria que possui produtos."
  end

  private

  def set_product_category
    @product_category = ProductCategory.find(params[:id])
  end

  def product_category_params
    params.require(:product_category).permit(
      :name,
      :description,
      :sort_order
    )
  end
end
