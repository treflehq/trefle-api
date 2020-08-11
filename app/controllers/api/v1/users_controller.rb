class Api::V1::UsersController < Api::ApiController


  def me
    render json: {
      name: @jwt ? nil : current_user.name,
      email: @jwt ? nil : current_user.email,
      image_url: current_user.gravatar_url,
      organization_name: current_user.organization_name,
      organization_url: current_user.organization_url,
      account_type: current_user.account_type,
      created_at: @jwt ? nil : current_user.created_at,
    }
  end
end
