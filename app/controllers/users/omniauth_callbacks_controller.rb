class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :check_authentication
  skip_before_action :check_activity

  def oktaoauth
    # Please leave the following line of code for debugging Okta session issues
    # session[:oktastate] = request.env["omniauth.auth"]  #store all okta data in session
    session[:netid] = request.env['omniauth.auth'].extra.raw_info.netid
    @user = User.where(username: session[:netid]).first_or_create
    @user.last_activity_at = Time.zone.now
    @user.save!
    sign_in_and_redirect @user
  end

  protected

  def after_omniauth_failure_path_for resource
    root_path
  end
end
