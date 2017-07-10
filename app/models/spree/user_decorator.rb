if Spree.user_class
  Spree.user_class.class_eval do

    after_create  :subscribe
    around_update :resubscribe
    after_destroy :unsubscribe
    after_initialize :assign_subscription_default

    delegate :subscribe, :resubscribe, :unsubscribe, to: :subscription
    
#    after_find :transform_mailchimp_lists_ids

    # def transform_mailchimp_lists_ids
    #   return if !self.mailchimp_lists_ids
    #   JSON.parse self.mailchimp_lists_ids
    # end

  private
    def subscription
      Spree::Chimpy::Subscription.new(self)
    end

    def assign_subscription_default
      self.subscribed ||= Spree::Chimpy::Config.subscribed_by_default if new_record?
    end
  end
end
