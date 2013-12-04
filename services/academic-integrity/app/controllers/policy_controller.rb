class PolicyController < ApplicationController

  rescue_from ActiveRecord::RecordNotFound, :with => :handle_missing_record

  def show
    @policy = Policy.find(params[:id])
  end

  def new
    render 'public/403.html', status: :forbidden and return unless verify_permissions
  end

  def edit
    render 'public/403.html', status: :forbidden and return unless verify_permissions
    @policy = Policy.find(params[:id])
  end

  def create
    render 'public/500.html', status: :internal_server_error and return unless verify_session
    render 'public/403.html', status: :forbidden and return unless verify_permissions
    render 'public/400.html', status: :bad_request and return unless verify_params

    policy = Policy.new(params.require(:policy).permit(:title, :text))
    policy.creator_id = session[:user_id]
    policy.creator_course_label = session[:context_label]
    policy.creator_course_id = session[:context_id]
    set_public_if_allowed(policy)
    policy.save

    course = Course.find_by(:context_id => session[:context_id])
    course.policy_id = policy.id
    course.save

    redirect_to course_url(course)
  end

  def update
    render 'public/500.html', status: :internal_server_error and return unless verify_session
    render 'public/403.html', status: :forbidden and return unless verify_permissions
    render 'public/400.html', status: :bad_request and return unless verify_params
    policy = Policy.find(params[:id])
    policy.text = params[:policy][:text]
    policy.title = params[:policy][:title]
    set_public_if_allowed(policy)
    policy.save

    course = Course.find_by(:context_id => session[:context_id])
    redirect_to course_url(course)
  end

  def text
    policy = Policy.find(params[:id])
    render text: policy.text
  end

  private

  def handle_missing_record
    render 'public/404.html', status: :not_found and return
  end

  def verify_permissions
    return (session[:roles] & [:instructor, :administrator, :content_developer]).any?
  end

  def verify_params
    return params[:policy] && params[:policy][:text] && params[:policy][:title]
  end

  def check_session_entry(label)
    return session[label] && session[label].length > 0
  end

  def verify_session
    return check_session_entry(:context_id) &&
    check_session_entry(:context_label) &&
    check_session_entry(:context_title) &&
    check_session_entry(:user_id) &&
    check_session_entry(:ext_content_return_url) &&
    check_session_entry(:ext_content_return_types) &&
    check_session_entry(:roles)
  end

  def set_public_if_allowed(policy)
    if (session[:roles].include? :administrator) && params[:policy][:is_public]
      policy.is_public = true
    else
      policy.is_public = false
    end
  end
end
