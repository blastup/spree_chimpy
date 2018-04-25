if Spree.user_class
  Spree.user_class.class_eval do

    after_create  :subscribe
    around_update :resubscribe
    after_destroy :unsubscribe
    after_initialize :assign_subscription_default

    delegate :subscribe, :resubscribe, :unsubscribe, to: :subscription
    
    after_find :transform_mailchimp_lists_ids

    def transform_mailchimp_lists_ids
      return if !self.mailchimp_lists_ids
      JSON.parse self.mailchimp_lists_ids.to_s
    end

  private
    def subscription
      Spree::Chimpy::Subscription.new(self)
    end

    def assign_subscription_default
      if new_record? || id_changed?
        self.subscribed ||= Spree::Chimpy::Config.subscribed_by_default 
        
        default_list_id = Spree::Chimpy::Config[:list_id] 
        if !default_list_id
          default_list = Spree::Chimpy::Interface::List.new(Spree::Chimpy::Config[:list_name],
                        Spree::Chimpy::Config.customer_segment_name,
                        Spree::Chimpy::Config.double_opt_in,
                        Spree::Chimpy::Config.send_welcome_email,
                        Spree::Chimpy::Config.list_id)
          default_list_id = default_list.list_id
        end
        self.mailchimp_lists_ids ||= ["#{default_list_id}"].to_json
      end
    end
  end
end
