class AddListToUsers < ActiveRecord::Migration
  def change
    add_column :spree_users, :mailchimp_lists_ids, :json, null: true, default: nil
  end

end
