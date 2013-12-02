class LtiController < ApplicationController

  class BadInput < StandardError
    attr_reader :message, :params
    def initialize(data)
      @message = data[:message]
      @params = data[:params].except!(:controller, :action)
    end
  end
  rescue_from BadInput, :with => :handle_bad_input

  def index
  end

  def service
    @host = request.host
    @port = request.port
  end

  def launch
    check_param_not_empty(:context_id)
    check_param_not_empty(:context_label)
    check_param_not_empty(:context_title)
    check_param_not_empty(:user_id)
    check_param_not_empty(:roles)
    check_param_not_empty(:ext_content_return_url)
    check_param_not_empty(:ext_content_return_types)

    return_types = parse_return_types
    roles = parse_roles

    verify_return_types(return_types)
    verify_roles(roles)

    params.each do |key, value|
      session[key] = value
    end
    session[:roles] = roles
    session[:ext_content_return_types] = return_types

    course = Course.find_by context_id: params[:context_id]
    if course == nil
      course = Course.new
      course.save
    end

    redirect_to course_url(course)
  end

  private
  
  def check_param_not_empty(param_name)
    param = params[param_name]
    unless param != nil && param.class == String && param.length > 0
      raise BadInput.new({ :params => params, :message => "Required field #{param_name} not set"})
    end
  end

  def handle_bad_input(exception)
    render json: { :message => exception.message, :params => exception.params }.to_json, :status => 400
  end

  def verify_roles(roles)
    useful_roles = [:learner, :instructor, :content_developer, :administrator, :teaching_assistant]
    if (roles & useful_roles).empty?
      raise BadInput.new({ :params => params, :message => "Launch parameters must supply at least one role from #{useful_roles}"})
    end
  end

  def verify_return_types(return_types)
    unless return_types.include?(:iframe)
      raise BadInput.new({ :params => params, :message => "ext_content_return_types must contain 'iframe'"})
    end
  end

  def parse_roles()
    role_labels = []
    params[:roles].split(",").each do |role|
      case role
      when /Learner|urn:lti:role:ims\/lis\/Learner/
        role_labels << :learner
      when /Instructor|urn:lti:role:ims\/lis\/Instructor/
        role_labels << :instructor
      when "urn:lti:role:ims/lis/TeachingAssistant"
        role_labels << :teaching_assistant
      when /ContentDeveloper|urn:lti:role:ims\/lis\/ContentDeveloper/
        role_labels << :content_developer
      when "urn:lti:instrole:ims/lis/Observer"
        role_labels << :observer
      when "urn:lti:instrole:ims/lis/Administrator"
        role_labels << :administrator
      end
    end
    role_labels
  end

  def parse_return_types()
    labels = []
    params[:ext_content_return_types].split(",").each do |type|
      case type
      when "oembed"
        labels << :oembed
      when "lti_launch_url"
        labels << :lti_launch_url
      when "url"
        labels << :url
      when "image_url"
        labels << :image_url
      when "iframe"
        labels << :iframe
      end
    end
    labels
  end

end
