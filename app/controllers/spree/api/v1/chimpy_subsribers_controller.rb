module Spree
  module Api
    module V1
      class ChimpySubscribersController < Spree::Api::BaseController

        def create
          @subscriber = Spree::Chimpy::Subscriber.where(email: subscriber_params[:email]).first_or_initialize
          @subscriber.email = subscriber_params[:email]
          @subscriber.subscribed = subscriber_params[:subscribed]

          user = Spree::User.find_by_email(subscriber_params[:email])
          user.update(:subscribed => subscriber_params[:subscribed]) unless !user.present?

          if Spree::Chimpy::Subscriber.find_by_email(subscriber_params[:email])
            render "spree/api/v1/chimpy_subscribers/subscriber_exists", :status => 401 and return
          elsif @subscriber.save
            respond_with(@subscriber, default_template: :show, locals: { root_object: @subscriber })
          else
            render "spree/api/errors/unauthorized", status: :unauthorized
          end
        end

        private

          def subscriber_params
            params.require(:chimpy_subscriber).permit(:email, :subscribed)
          end

      end
    end
  end
end