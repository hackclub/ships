module Api
  module V1
    class MeController < ApplicationController
     before_action :require_login

      def index
        users_projects = YswsProjectEntry.where(email: current_user.email)

        render json: users_projects
      end
    end
  end
end
