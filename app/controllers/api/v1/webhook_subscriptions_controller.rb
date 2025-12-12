module Api
  module V1
    # Manages webhook subscriptions for the authenticated user.
    class WebhookSubscriptionsController < ApplicationController
      before_action :require_login
      before_action :set_subscription, only: [ :show, :update, :destroy ]

      # GET /api/v1/webhook_subscriptions
      # Returns all webhook subscriptions for the current user.
      def index
        subscriptions = current_user.webhook_subscriptions

        render json: subscriptions.map { |s| subscription_json(s) }
      end

      # GET /api/v1/webhook_subscriptions/:id
      # Returns a single webhook subscription.
      def show
        render json: subscription_json(@subscription)
      end

      # POST /api/v1/webhook_subscriptions
      # Creates a new webhook subscription.
      def create
        subscription = current_user.webhook_subscriptions.build(subscription_params)

        if subscription.save
          render json: subscription_json(subscription), status: :created
        else
          render json: { errors: subscription.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/webhook_subscriptions/:id
      # Updates an existing webhook subscription.
      def update
        if @subscription.update(subscription_params)
          render json: subscription_json(@subscription)
        else
          render json: { errors: @subscription.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/webhook_subscriptions/:id
      # Deletes a webhook subscription.
      def destroy
        @subscription.destroy
        head :no_content
      end

      private

      def set_subscription
        @subscription = current_user.webhook_subscriptions.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Subscription not found" }, status: :not_found
      end

      def subscription_params
        params.require(:webhook_subscription).permit(:event_type, :url, :active, :slack_dm)
      end

      def subscription_json(subscription)
        {
          id: subscription.id,
          event_type: subscription.event_type,
          url: subscription.url,
          active: subscription.active,
          slack_dm: subscription.slack_dm,
          created_at: subscription.created_at.iso8601,
          updated_at: subscription.updated_at.iso8601
        }
      end
    end
  end
end
