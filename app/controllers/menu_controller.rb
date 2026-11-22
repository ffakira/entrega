class MenuController < ApplicationController
  allow_unauthenticated_access only: :index

  def index
    @products_by_category = ProductCategory
      .active
      .ordered
      .map do |category|
        products = category.products
          .available
          .ordered
          .with_attached_image
          .to_a

        [category, products]
      end
      .reject { |_, products| products.empty? }
  end
end
