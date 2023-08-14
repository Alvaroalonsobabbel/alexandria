class AddErrorToPurchase < ActiveRecord::Migration[7.0]
  def change
    add_column :purchases, :error, :text
  end
end
