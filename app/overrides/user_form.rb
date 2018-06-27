Deface::Override.new(:virtual_path => "spree/admin/users/_configurations",
                     :name         => "user_form_subscription",
                     :insert_after => "[data-hook=admin_user_push_to_amsterdam]",
                     :partial      => "spree/shared/user_subscription")
