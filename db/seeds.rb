# Default categories for the initial AKARI menu.
# Category records remain editable application data.

[
  "Entradas",
  "Donburi",
  "Kare",
  "Yakisoba",
  "Sobremesas",
  "Bebidas"
].each_with_index do |name, index|
  category = ProductCategory.find_or_create_by!(name: name)

  # Apply the initial display order only to categories that have not
  # already been manually ordered.
  if category.sort_order.zero?
    category.update!(sort_order: index + 1)
  end
end
