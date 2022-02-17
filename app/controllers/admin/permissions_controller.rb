module Admin
  class PermissionsController < Admin::ApplicationController
    layout "admin"

    def index
      @users = User.with_role(:admin)
        .union(User.with_role(:super_admin))
        .union(User.with_role(:single_resource_admin, :any))
        .page(params[:page])
        .per(50)
    end
  end
end
