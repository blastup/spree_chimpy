require 'spree_core'
require 'spree/chimpy/engine'
require 'spree/chimpy/subscription'
require 'spree/chimpy/workers/delayed_job'
require 'mailchimp'
require 'coffee_script'

module Spree::Chimpy
  extend self

  def config(&block)
    yield(Spree::Chimpy::Config)
  end

  def enqueue(event, object, *args)
    payload = {class: object.class.name, id: object.id, object: object, args: args}
    ActiveSupport::Notifications.instrument("spree.chimpy.#{event}", payload)
  end

  def log(message)
    Rails.logger.info "spree_chimpy: #{message}"
  end

  def configured?
    Config.key.present? && (Config.list_name.present? || Config.list_id.present?)
  end

  def reset
    @list = @api = @orders = nil
  end

  def api
    @api = Mailchimp::API.new(Config.key, Config.api_options) if configured?
  end

  def list(list_name = nil)
    if list_name
      @list = Interface::List.new(list_name,
                        Config.customer_segment_name,
                        Config.double_opt_in,
                        Config.send_welcome_email,
                        Config.list_id) if configured?
    else
      @list ||= Interface::List.new(Config.list_name,
                        Config.customer_segment_name,
                        Config.double_opt_in,
                        Config.send_welcome_email,
                        Config.list_id) if configured?
    end
  end

  def set_list(id)
    @list = Interface::List.new(nil,
                        Config.customer_segment_name,
                        Config.double_opt_in,
                        Config.send_welcome_email,
                        id) if configured?
  end

  def set_list(id)
    @list = Interface::List.new(nil,
                        Config.customer_segment_name,
                        Config.double_opt_in,
                        Config.send_welcome_email,
                        id) if configured?
  end

  def orders
    @orders ||= Interface::Orders.new if configured?
  end

  def list_exists?
    list.list_id
  end

  def segment_exists?
    list.segment_id
  end

  def create_segment
    list.create_segment
  end

  def sync_merge_vars
    existing   = list.merge_vars + %w(EMAIL)
    merge_vars = Config.merge_vars.except(*existing)

    merge_vars.each do |tag, method|
      list.add_merge_var(tag.upcase, method.to_s.humanize.titleize)
    end
  end

  def merge_vars(model)
    attributes = Config.merge_vars.except('EMAIL')

    array = attributes.map do |tag, method|
      value = model.send(method) if model.methods.include?(method)

      [tag, value.to_s]
    end

    Hash[array]
  end

  def ensure_list
    if Config.list_name.present?
      Rails.logger.error("spree_chimpy: hmm.. a list named `#{Config.list_name}` was not found. Please add it and reboot the app") unless list_exists?
    end
    if Config.list_id.present?
      Rails.logger.error("spree_chimpy: hmm.. a list with ID `#{Config.list_id}` was not found. Please add it and reboot the app") unless list_exists?
    end
  end

  def ensure_segment
    if list_exists? && !segment_exists?
      create_segment
      Rails.logger.error("spree_chimpy: hmm.. a static segment named `#{Config.customer_segment_name}` was not found. Creating it now")
    end
  end

  def handle_event(event, payload = {})
    payload[:event] = event

    case
    when defined?(::Delayed::Job)
      ::Delayed::Job.enqueue(Spree::Chimpy::Workers::DelayedJob.new(payload))
    when defined?(::Sidekiq)
      Spree::Chimpy::Workers::Sidekiq.perform_async(payload.except(:object))
    else
      perform(payload)
    end
  end

  def perform(payload)
    return unless configured?

    event  = payload[:event].to_sym
    object = payload[:object] || payload[:class].constantize.find(payload[:id])
    args   = payload[:args]

    case event
    when :order
      orders.sync(object)
    when :subscribe
      new_lists_ids = args[0]

      if new_lists_ids && new_lists_ids.length > 0
        new_lists_ids.each do |id|
          set_list(id)
          list.subscribe(object.email, merge_vars(object), customer: object.is_a?(Spree.user_class))
        end

      # Check if spree_multi_domain gem is applied and thus we have multiple stores
      elsif Spree::Store.column_names.include?('extra_settings')
        default_list_name = get_default_list_form_store( object.is_a?(Spree.user_class) ? object.subscribed_to_store_id : nil)
        list( default_list_name ).subscribe(object.email, merge_vars(object), customer: object.is_a?(Spree.user_class)) if default_list_name
      else
        list.subscribe(object.email, merge_vars(object), customer: object.is_a?(Spree.user_class))
      end
    
    when :unsubscribe
      removed_lists_ids = args[0]
      if removed_lists_ids && removed_lists_ids.length > 0
        removed_lists_ids.each do |id|
          set_list(id)
          list.unsubscribe(object.email)
        end
      
      # Check if spree_multi_domain gem is applied and thus we have multiple stores
      elsif Spree::Store.column_names.include?('extra_settings')
        default_list_name = get_default_list_form_store( object.is_a?(Spree.user_class) ? object.subscribed_to_store_id : nil)
        list( default_list_name ).unsubscribe(object.email) if default_list_name
      else
        list.unsubscribe(object.email)
      end
    end
  end

  private
    def get_default_list_form_store(store_id)
      if store_id
        store = Spree::Store.find_by_id(store_id)
        return store ? store.extra_settings[:mailchimp_list] : nil
      end
      
      return nil
    end
end
