class RemoveErrorFromPurchase < ActiveRecord::Migration[7.0]
  def change
    remove_column :purchases, :error
  end
end
