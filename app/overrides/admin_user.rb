Deface::Override.new(:virtual_path => "spree/admin/users/_newsletters",
                     :name         => "admin_user_form_subscription",
                     :insert_top => "[data-hook=admin_user_newsletters]",
                     :partial      => "spree/admin/users/subscription_form")

Deface::Override.new(:virtual_path => "spree/admin/users/show",
                     :name         => "admin_user_show_subscription",
                     :insert_after => "table tr:last",
                     :partial      => "spree/admin/users/subscription")