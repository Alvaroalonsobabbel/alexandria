class AddConfirmationRedirectUrlToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :confirmation_redirect_url, :text
  end
end
