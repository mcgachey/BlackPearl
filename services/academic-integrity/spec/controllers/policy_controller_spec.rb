require 'spec_helper'

describe PolicyController do
  include_context "setup"
  include_context "utils"

  def get_launch_params
    params = { "policy" => {"text" => "Text", "title" => "Title", "is_public" => false}}
  end

  def make_policy_public(verb, action, extra_params, role, success)
    session[:roles] = [role]
    params = get_launch_params.merge(extra_params)
    params["policy"]["is_public"] = true
    policy_obj = Policy.new
    Policy.stub(:new).and_return(policy_obj)
    Policy.stub(:find).and_return(policy_obj)
    self.send verb, action, params
    response.status.should == 302
    policy_obj.is_public.should == success
  end

  context "Create new policy" do

    it "returns forbidden if the user is not an instructor, designer or admin" do
      check_permissions_for_roles(:post, :create, {})
    end

    it "fails gracefully if there is no policy parameter" do
      params = {}
      launch_expecting_failure(:post, :create, params, 400)
    end

    it "fails gracefully if there is no title parameter" do
      params = {:policy => {:text => "Text"}}
      launch_expecting_failure(:post, :create, params, 400)
    end

    it "fails gracefully if there is no text parameter" do
      params = {:policy => {:title => "Title"}}
      launch_expecting_failure(:post, :create, params, 400)
    end

    def launch_without_session_variable(var)
      session.delete var
      launch_expecting_failure(:post, :create, get_launch_params, 500)
    end

    it "fails gracefully if required parameters are missing from the session" do
      launch_without_session_variable(:context_id)
      launch_without_session_variable(:context_label)
      launch_without_session_variable(:context_title)
      launch_without_session_variable(:user_id)
      launch_without_session_variable(:ext_content_return_url)
      launch_without_session_variable(:roles)
      launch_without_session_variable(:ext_content_return_types)
    end

    it "creates policy model with the correct fields" do
      params = get_launch_params
      obj_params = {"text" => params["policy"]["text"], "title" => params["policy"]["title"]}
      policy_obj = Policy.new(obj_params)
      Policy.should_receive(:new).with(obj_params).and_return(policy_obj)
      post :create, params
      policy_obj.id.should_not be_nil
      policy_obj.text.should == params["policy"]["text"]
      policy_obj.title.should == params["policy"]["title"]
      policy_obj.creator_id.should == session[:user_id]
      policy_obj.creator_course_id.should == session[:context_id]
      policy_obj.creator_course_label.should == session[:context_label]
      policy_obj.is_public.should == false
    end

    it "doesn't set policy as public unless user is an admin" do
      make_policy_public(:post, :create, {}, :administrator, true)
      make_policy_public(:post, :create, {}, :instructor, false)
      make_policy_public(:post, :create, {}, :content_developer, false)
    end

    it "sets the new policy as selected for the current course" do
      params = get_launch_params
      policy_obj = Policy.new()
      Policy.stub(:new).and_return(policy_obj)
      post :create, params
      course = Course.find_by(:context_id => session[:context_id])
      course.policy_id.should == policy_obj.id
    end

    it "redirects to the course view page" do
      params = get_launch_params
      post :create, params
      course = Course.find_by(:context_id => session[:context_id])
      response.should redirect_to(course_url(course))
    end
  end

  context "Update existing policy" do

    before(:all) do
      @policy = Policy.new
      @policy.save
    end

    it "returns forbidden if the user is not an instructor, designer or admin" do
      check_permissions_for_roles(:put, :update, {:id => 1})
    end

    it "fails gracefully if there is no policy parameter" do
      params = {:id => @policy.id}
      launch_expecting_failure(:put, :update, params, 400)
    end

    it "fails gracefully if there is no title parameter" do
      params = {:policy => {:text => "Text"}, :id => @policy.id}
      launch_expecting_failure(:put, :update, params, 400)
    end

    it "fails gracefully if there is no text parameter" do
      params = {:policy => {:title => "Title"}, :id => @policy.id}
      launch_expecting_failure(:put, :update, params, 400)
    end

    it "fails gracefully if the policy is not found" do
      params = get_launch_params.merge({:id => 0})
      Policy.stub(:find).and_raise(ActiveRecord::RecordNotFound.new)
      launch_expecting_failure(:put, :update, params, 404)
    end

    it "doesn't set policy as public unless user is an admin" do
      make_policy_public(:put, :update, {:id => @policy.id}, :administrator, true)
      make_policy_public(:put, :update, {:id => @policy.id}, :instructor, false)
      make_policy_public(:put, :update, {:id => @policy.id}, :content_developer, false)
    end

    it "updates the policy" do
      params = get_launch_params.merge({:id => @policy.id})
      params["policy"]["text"] = "Updated Text"
      params["policy"]["title"] = "Updated Title"
      Policy.stub(:find).and_return(@policy)
      put :update, params
      @policy.text.should == params["policy"]["text"]
      @policy.title.should == params["policy"]["title"]
    end

    it "saves the policy" do
      params = get_launch_params.merge({:id => @policy.id})
      Policy.stub(:find).and_return(@policy)
      @policy.should_receive(:save)
      put :update, params
    end

    it "redirects to the view page for the current course after updating" do
      params = get_launch_params.merge({:id => @policy.id})
      put :update, params
      course = Course.find_by(:context_id => session[:context_id])
      response.should redirect_to(course_url(course))
    end
  end

  context "Show a policy" do

    before(:all) do
      @p = Policy.new
      @p.save
    end

    it "fails gracefully if the policy is not found" do
      params = { :id => 0 }
      Policy.stub(:find).and_raise(ActiveRecord::RecordNotFound.new)
      launch_expecting_failure(:get, :show, params, 404)
    end

    it "loads the policy identified by the id parameter" do
      params = { :id => @p.id }
      Policy.stub(:find).and_return(@p)
      get :show, params
      assigns(:policy).should == @p
    end

    it "doesn't prevent iframe for response" do
      params = { :id => @p.id }
      get :show, params
      response.headers["X-Frame-Options"].should be_nil
    end
  end

  context "Show new policy page" do

    it "fails gracefully if the user is not an instructor, designer or admin" do
      check_permissions_for_roles(:get, :new, {})
    end

    it "doesn't prevent iframe for response" do
      get :new
      response.headers["X-Frame-Options"].should be_nil
    end
  end

  context "Show a policy edit page" do

    before(:all) do
      @p = Policy.new
      @p.save
    end

    it "fails gracefully if the user is not an instructor, designer or admin" do
      params = { :id => @p.id }
      check_permissions_for_roles(:get, :edit, params)
    end

    it "fails gracefully if the policy is not found" do
      params = get_launch_params.merge({:id => 0})
      Policy.stub(:find).and_raise(ActiveRecord::RecordNotFound.new)
      launch_expecting_failure(:get, :edit, params, 404)
    end

    it "loads the policy identified by the id parameter" do
      params = { :id => @p.id }
      Policy.stub(:find).and_return(@p)
      get :edit, params
      assigns(:policy).should == @p
    end

    it "doesn't prevent iframe for response" do
      params = { :id => @p.id }
      get :edit, params
      response.headers["X-Frame-Options"].should be_nil
    end
  end

  context "Get the text for a policy" do

    before(:all) do
      @p = Policy.new
      @p.text = "Text of the policy"
      @p.save
    end

    it "fails gracefully if the policy is not found" do
      params = get_launch_params.merge({:id => 0})
      Policy.stub(:find).and_raise(ActiveRecord::RecordNotFound.new)
      launch_expecting_failure(:get, :text, params, 404)
    end

    it "returns the full text of the policy" do
      params = { :id => @p.id }
      Policy.stub(:find).and_return(@p)
      get :text, params
      response.body.should == @p.text
    end
  end

end
