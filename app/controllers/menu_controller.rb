class MenuController < ApplicationController
  allow_unauthenticated_access only: :index

  def index
    @products_by_category = Product.available
      .ordered
      .group_by(&:category)
  end
end
