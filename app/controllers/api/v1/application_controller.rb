module Api
  module V1
    class ApplicationController < ActionController::API
      # Returns the currently logged-in user, if any.
      # Supports both session-based auth and API key auth via Authorization header.
      #
      # @return [User, nil] The current user or nil if not authenticated.
      def current_user
        @current_user ||= authenticate_from_api_key || authenticate_from_session
      end

      # Checks if a user is currently authenticated.
      #
      # @return [Boolean] True if a user is authenticated, false otherwise.
      def logged_in?
        current_user.present?
      end

      # Ensures the user is authenticated before accessing protected endpoints.
      def require_login
        unless logged_in?
          render json: { error: "Authentication required" }, status: :unauthorized
        end
      end

      private

      # Authenticates a user from the Authorization header (Bearer token).
      #
      # @return [User, nil] The authenticated user or nil.
      def authenticate_from_api_key
        auth_header = request.headers["Authorization"]
        return nil unless auth_header&.start_with?("Bearer ")

        api_key = auth_header.split(" ").last
        User.find_by(api_key: api_key)
      end

      # Authenticates a user from the session cookie (fallback for web clients).
      #
      # @return [User, nil] The authenticated user or nil.
      def authenticate_from_session
        User.find_by(id: session[:user_id]) if session[:user_id]
      end
    end
  end
end
