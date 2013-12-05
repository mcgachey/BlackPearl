class ApplicationController < ActionController::Base

  rescue_from ActiveRecord::RecordNotFound, :with => :handle_missing_record

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  after_action :allow_iframe

  private
  def handle_missing_record
    render 'public/404.html', status: :not_found and return
  end

  def verify_permissions
    return (session[:roles] & [:instructor, :administrator, :content_developer]).any?
  end

  def allow_iframe
    response.headers.except! 'X-Frame-Options'
  end
end
