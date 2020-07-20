class Management::UserQueriesController < Management::ManagementController
  before_action :set_user, only: %i[show edit update destroy]

  def index
    p = params.permit(:search, :dt, order: {})

    @user_queries = p[:dt] ? UserQuery.for_time(p[:dt]) : UserQuery.current
    @user_queries = @user_queries.order(p.to_h.dig('order')) if p[:order]
    @user_queries = @user_queries.order(counter: :desc) unless p[:order]

    @pagy, @user_queries = pagy(@user_queries)
  end

  def stats
    limit = 1.month.ago.strftime('%y%m%d%H')
    @counters = UserQuery.where('time > ?', limit).group('time / 100').sum(:counter).map {|k, v| { value: v, name: k } }

    @heatmap = UserQuery.where('time > ?', limit).group(:time).sum(:counter).map do |k, v|
      date = UserQuery.convert_datetime(k.to_s)
      {
        value: v,
        day: date.strftime('%u').to_i - 1,
        hour: date.strftime('%k').to_i
      }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = User.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def user_params
    params.require(:user).permit(:name, :email, :password_hash, :reset_password_token, :reset_password_sent_at, :failed_attempts, :locked_at, :sign_in_count, :current_sign_in_at, :last_sign_in_at, :current_sign_in_ip, :last_sign_in_ip, :unlock_token, :confirmation_token, :confirmed_at, :confirmation_sent_at, :inserted_at, :admin, :token, :organization_name, :organization_url, :organization_image_url, :account_type, :public_profile)
  end
end
