class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  #protect_from_forgery with: :exception
  #protect_from_forgery with: :null_session
  helper_method :cobSessionToken, :userSessionToken, :logs

  def cobSessionToken
    @cobSessionToken ||= session[:cobSessionToken] if session[:cobSessionToken]
  end

  def userSessionToken
    @userSessionToken ||= session[:userSessionToken] if session[:userSessionToken]
  end

  def logs
    @logs ||= session[:logs] if session[:logs]
  end

  def sandbox
    Yodlee::Config.base_url == "https://rest.developer.yodlee.com/services/srest/restserver/v1.0"
  end
end
