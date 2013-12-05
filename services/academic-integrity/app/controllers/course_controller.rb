class CourseController < ApplicationController

  def show
    @course = Course.find(params[:id])
    if @course.policy_id
      @policy = Policy.find(@course.policy_id)
    end
    @instructor = session[:roles].include?(:instructor)
  end

  def edit
    render 'public/403.html', status: :forbidden and return unless verify_permissions
    @course = Course.find(params[:id])
    if @course.policy_id
      @policy = Policy.find(@course.policy_id)
    end
    @policies = Policy.where("is_public = ? OR creator_id = ? OR creator_course_label = ? OR creator_course_id = ?", 
                              true, session[:user_id], session[:context_label], session[:context_id])
  end

  def update
    render 'public/403.html', status: :forbidden and return unless verify_permissions
    render 'public/400.html', status: :bad_request and return unless verify_params
    render 'public/404.html', status: :not_found and return unless Policy.find(params[:course][:policy_id])
    course = Course.find(params[:id])
    course.policy_id = params[:course][:policy_id]
    course.save
    redirect_to course
  end

  def return_to_lms
    render 'public/403.html', status: :forbidden and return unless verify_permissions
    course = Course.find(params[:id])
    if course.policy_id
      url = url_for :controller => "course", :action => "show", :id => course.id
      params = {
        :return_type => :iframe,
        :url => url,
        :width => '100%',
        :height => '300'
      }
      if session[:ext_content_return_url].include?("?")
        redirect = "#{session[:ext_content_return_url]}&#{params.to_query}"
      else
        redirect = "#{session[:ext_content_return_url]}?#{params.to_query}"
      end
      redirect_to redirect
    else 
      redirect_to "#{session[:ext_content_return_url]}"
    end
  end

private
  def verify_params
    return params[:course] && params[:course][:policy_id]
  end

end
