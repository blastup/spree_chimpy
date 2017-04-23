class AddSubscribedFromStoreIdToUser < ActiveRecord::Migration
  def change
    add_column :spree_users, :subscribed_to_store_id, :integer
  end
end
