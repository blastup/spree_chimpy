module Spree::Chimpy
  class Subscription
    delegate :configured?, :enqueue, to: Spree::Chimpy

    def initialize(model)
      @model      = model
    end

    def subscribe
      return unless configured?
      defer(:subscribe) if subscribing?
    end

    def unsubscribe
      return unless configured?
      defer(:unsubscribe) if unsubscribing?
    end

    def unsubscribe
      return unless configured?
      defer(:unsubscribe) if unsubscribing?
    end

    def resubscribe(&block)
      block.call if block

      return unless configured?
      if unsubscribing?
        defer(:unsubscribe)
      elsif subscribing? || merge_vars_changed?
        defer(:subscribe)
      elsif lists_have_changed?
        defer(:subscribe, new_lists) if new_lists.length > 0
        defer(:unsubscribe, removed_lists) if removed_lists.length > 0
      end
    end

  private
    def defer(event)
      enqueue(event, @model)
    end

    def defer(event, *args)
      enqueue(event, @model, *args)
    end
    
    def prev_lists_ids
      return [] if @model.changes[:mailchimp_lists_ids][0].nil?
      JSON.parse(@model.changes[:mailchimp_lists_ids][0])
    end
    
    def new_lists_ids
      JSON.parse(@model.changes[:mailchimp_lists_ids][1])
    end

    def lists_have_changed?
      @model.changes[:mailchimp_lists_ids] && (prev_lists_ids != new_lists_ids)
    end

    def new_lists
      new_lists_ids - prev_lists_ids
    end

    def removed_lists
      prev_lists_ids - new_lists_ids
    end

    def subscribing?
      @model.subscribed && (@model.subscribed_changed? || @model.id_changed? || @model.new_record?)
    end

    def unsubscribing?
      !@model.id_changed? && !@model.new_record? && !@model.subscribed && @model.subscribed_changed?
    end

    def merge_vars_changed?
      Config.merge_vars.values.any? do |attr|
        name = "#{attr}_changed?".to_sym
        !@model.methods.include?(name) || @model.send(name)
      end
    end
  end
end
