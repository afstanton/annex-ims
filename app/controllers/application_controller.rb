class ApplicationController < ActionController::Base
  before_action :check_authentication
  before_action :check_activity
  before_action :set_sentry_context

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :user_admin?

  protected

  def check_authentication
    unless user_signed_in?
      redirect_to_sign_in
      return
    end
    redirect_to_unauthorized unless user_admin? || user_worker?
  end

  def check_activity
    if current_user.blank? || IsUserSessionExpired.call(user: current_user)
      sign_out
      render 'users/timed_out'
      return
    end
    update_activity
  end

  def redirect_to_sign_in
    # repost gem will redirect as a method: :post
    repost(user_oktaoauth_omniauth_authorize_path, options: { authenticity_token: :auto })
  end

  def redirect_to_unauthorized
    raise_404
  end

  def raise_404(message = 'Not Found')
    fail ActionController::RoutingError.new(message)
  end

  def user_admin?
    config_admin = ''
    if Rails.configuration.respond_to? :admin_user_name
      config_admin = Rails.configuration.admin_user_name
    end
    current_user.admin || (config_admin == current_user.username)
  end

  def user_worker?
    current_user.worker
  end

  def require_admin
    redirect_to_unauthorized if user_admin? == false
  end

  def update_activity
    current_user&.touch(:last_activity_at)
  end

  private

  def set_sentry_context
    Sentry.set_user(id: session[:current_user_id]) # or anything else in session
    Sentry.set_extras(params: params.to_unsafe_h, url: request.url)
  end

  # Overwriting the sign_out redirect path method
  def after_sign_out_path_for(*)
    Rails.application.secrets.okta[:logout_url]
  end
end
