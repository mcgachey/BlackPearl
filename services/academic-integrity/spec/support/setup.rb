shared_context "setup" do
  before(:each) do
    session[:context_id] = "contextid_123"
    session[:context_label] = "contextlabel_123"
    session[:context_title] = "Context Title"
    session[:user_id] = "userid_123"
    session[:roles] = [ :instructor ]
    session[:ext_content_return_url] = "http://example.com/content_return_url"
    session[:ext_content_return_types] = [ :oembed, :lti_launch_url, :url, :image_url, :iframe ]

    course = Course.new
    course.context_id = session[:context_id]
    course.save
  end
end

shared_context "utils" do
  def launch_expecting_failure(verb, action, params, status)
    self.send verb, action, params
    response.status.should == status
    response.should render_template(:file => "#{Rails.root}/public/#{status}.html")
  end

  def launch_with_roles(verb, action, extra_params, roles, success)
    session[:roles] = roles
    params = get_launch_params.merge(extra_params)
    if success
      self.send verb, action, params
      response.status.should < 400
    else
      launch_expecting_failure(:post, action, params, 403)
    end
  end

  def check_permissions_for_roles(verb, action, params)
    launch_with_roles(verb, action, params, [:administrator], true)
    launch_with_roles(verb, action, params, [:instructor], true)
    launch_with_roles(verb, action, params, [:content_developer], true)
    launch_with_roles(verb, action, params, [:learner], false)
    launch_with_roles(verb, action, params, [:teaching_assistant], false)
    launch_with_roles(verb, action, params, [:administrator, :instructor, :content_developer], true)
    launch_with_roles(verb, action, params, [:instructor, :learner], true)
    launch_with_roles(verb, action, params, [:teaching_assistant, :learner], false)
  end

end
