require 'spec_helper'

describe CourseController do
  include_context "setup"
  include_context "utils"

  before(:each) do
    @p = Policy.new
    @p.save
    @c = Course.new
    @c.policy_id = @p.id
    @c.save
  end

  def get_launch_params
    {}
  end

  context "Show course page" do

    it "fails gracefully if the course does not exist" do
      Course.stub(:find).and_raise(ActiveRecord::RecordNotFound.new)
      launch_expecting_failure(:get, :show, { :id => 0 }, 404)
    end

    it "finds the correct policy for the course" do
      get :show, { :id => @c.id }
      assigns(:policy).should == @p
    end

    it "doesn't find a policy if one is not set" do
      @c.policy_id = nil
      @c.save
      get :show, { :id => @c.id }
      assigns(:policy).should == nil
    end

    it "sets the instructor flag if the user has that role" do
      session[:roles] = [ :instructor ]
      get :show, { :id => @c.id }
      assigns(:instructor).should == true
    end

    it "does not set the instructor flag if the user doesn't have that role" do
      session[:roles] = [ :learner ]
      get :show, { :id => @c.id }
      assigns(:instructor).should == false
    end

    it "renders the course page" do
      get :show, { :id => @c.id }
      response.should render_template("show")
    end

  end

  context "Show edit page" do

    it "returns forbidden if the user is not an instructor, designer or admin" do
      check_permissions_for_roles(:get, :edit, { :id => @c.id })
    end

    it "fails gracefully if the course does not exist" do
      Course.stub(:find).and_raise(ActiveRecord::RecordNotFound.new)
      launch_expecting_failure(:get, :edit, { :id => 0 }, 404)
    end

    it "finds the correct policy for the course" do
      get :edit, { :id => @c.id }
      assigns(:policy).should == @p
    end

    it "doesn't find a policy if one is not set" do
      @c.policy_id = nil
      @c.save
      get :edit, { :id => @c.id }
      assigns(:policy).should == nil
    end

    def check_for_policy_in_list(policy)
      get :edit, { :id => @c.id }
      policies = assigns(:policies)
      policies.should_not be_nil
      policies.should include(policy)
    end

    it "lists all policies created by the current user" do
      p1 = Policy.new
      p1.creator_id = session[:user_id]
      p1.save
      check_for_policy_in_list(p1)
    end

    it "lists all policies created for the current course ID" do
      p1 = Policy.new
      p1.creator_course_id = session[:context_id]
      p1.save
      check_for_policy_in_list(p1)
    end

    it "lists all policies created for the current course label" do
      p1 = Policy.new
      p1.creator_course_label = session[:context_label]
      p1.save
      check_for_policy_in_list(p1)
    end

    it "lists all public policies" do
      p1 = Policy.new
      p1.is_public = true
      p1.save
      check_for_policy_in_list(p1)
    end

    it "doesn't list policies that are not visible to the current user" do
      p = Policy.new
      p.is_public = false
      p.save
      p = Policy.new
      p.creator_id = "userid_345"
      p.save
      p = Policy.new
      p.creator_course_id = "contextid_345"
      p.save
      p = Policy.new
      p.creator_course_label = "contextlabel_345"
      p.save
      get :edit, { :id => @c.id }
      policies = assigns(:policies)
      policies.should_not be_nil
      policies.empty?.should == true
    end

    it "renders the edit page" do
      get :edit, { :id => @c.id }
      response.should render_template("edit")
    end

  end

  context "Update selected policy for course" do

    before(:each) do
      @p2 = Policy.new
      @p2.save
    end

    def get_launch_params
      { "course" => { "policy_id" => @p2.id }}
    end

    it "returns forbidden if the user is not an instructor, designer or admin" do
      check_permissions_for_roles(:put, :update, get_launch_params.merge!({ :id => @c.id }))
    end

    it "fails gracefully if the course does not exist" do
      Course.stub(:find).and_raise(ActiveRecord::RecordNotFound.new)
      launch_expecting_failure(:put, :update, get_launch_params.merge!({ :id => @c.id }), 404)
    end

    it "fails gracefully if there is no course parameter" do
      params = { :id => @c.id }
      launch_expecting_failure(:put, :update, params, 400)
    end

    it "fails gracefully if there is no policy ID parameter" do
      params = { :id => @c.id, :course => {} }
      launch_expecting_failure(:put, :update, params, 400)
    end

    it "fails gracefully if the selected policy does not exist" do
      Policy.stub(:find).and_raise(ActiveRecord::RecordNotFound.new)
      launch_expecting_failure(:put, :update, get_launch_params.merge!({ :id => @c.id }), 404)
    end

    it "sets and saves the selected policy ID in the course" do
      put :update, get_launch_params.merge!({ :id => @c.id })
      Course.find(@c.id).policy_id.should == @p2.id
    end

    it "redirects to the course page" do
      put :update, get_launch_params.merge!({ :id => @c.id })
      response.should redirect_to(course_url(@c))
    end
  end

  context "Return control to LMS" do

    it "returns forbidden if the user is not an instructor, designer or admin" do
      check_permissions_for_roles(:put, :return_to_lms, get_launch_params.merge!({ :id => @c.id }))
    end

    it "fails gracefully if the course does not exist" do
      Course.stub(:find).and_raise(ActiveRecord::RecordNotFound.new)
      launch_expecting_failure(:post, :return_to_lms, get_launch_params.merge!({ :id => @c.id }), 404)
    end

    def get_redirection_url
      post :return_to_lms, get_launch_params.merge!({ :id => @c.id })
      response.status.should == 302
      URI.parse(response.header["Location"])
    end

    it "returns without data if no policy is selected" do
      @c.policy_id = nil
      @c.save
      return_url = session[:ext_content_return_url]
      post :return_to_lms, get_launch_params.merge!({ :id => @c.id })
      response.should redirect_to(return_url)
    end

    it "redirects to the session redirect URL if a course is selected" do
      return_url = session[:ext_content_return_url]
      url = get_redirection_url
      return_url = URI.parse(return_url)
      url.host.should == return_url.host
      url.port.should == return_url.port
      url.path.should == return_url.path
    end

    it "passes a URL-encoded JSON structure to the redirect URL" do
      url = get_redirection_url
      url.query.should_not be_nil
      query = CGI.parse(url.query)
      query.empty?.should == false
    end

    it "passes an iframe return type to the redirect URL" do
      url = get_redirection_url
      query = CGI.parse(url.query)
      query["return_type"][0].should == "iframe"
    end

    it "passes the URL of the course iframe view page to the redirect URL" do
      url = get_redirection_url
      query = CGI.parse(url.query)
      query["url"][0].should == "#{course_url(@c)}/iframe_view"
    end

    it "properly appends the query string to a URL containing a query" do
      session[:ext_content_return_url] = "http://example.com/address?with=query"
      post :return_to_lms, get_launch_params.merge!({ :id => @c.id })
      response.header["Location"].count("?").should == 1
    end

    it "clears the session before returning control" do
      post :return_to_lms, get_launch_params.merge!({ :id => @c.id })
      get_session_map.each { |k,v| session[k].should be_nil }
    end

  end

  context "Show course in an iframe" do

    it "fails gracefully if the course does not exist" do
      Course.stub(:find).and_raise(ActiveRecord::RecordNotFound.new)
      launch_expecting_failure(:get, :iframe_view, { :id => 0 }, 404)
    end

    it "finds the correct policy for the course" do
      get :iframe_view, { :id => @c.id }
      assigns(:policy).should == @p
    end

    it "doesn't find a policy if one is not set" do
      @c.policy_id = nil
      @c.save
      get :iframe_view, { :id => @c.id }
      assigns(:policy).should == nil
    end

    it "renders the course iframe page" do
      get :iframe_view, { :id => @c.id }
      response.should render_template("iframe_view")
    end

  end

end
