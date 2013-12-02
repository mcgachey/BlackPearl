require 'spec_helper'
require 'nokogiri'

describe LtiController do

  context "Service definition XML" do
    render_views

    def get_xml
      get :service, :format => :xml
      Nokogiri::XML(response.body)
    end

    # It's simpler to dictate the namespace labels, so that we can use them
    # in path expressions later. If necessary, this can be generalized and
    # subsequent tests updated. The labels here come from the XML generator at
    #    http://www.edu-apps.org/build_xml.html
    it "uses the LTI namespaces" do
      namespaces = get_xml.namespaces
      namespaces.size.should == 5
      namespaces["xmlns"].should == "http://www.imsglobal.org/xsd/imslticc_v1p0"
      namespaces["xmlns:blti"].should == "http://www.imsglobal.org/xsd/imsbasiclti_v1p0"
      namespaces["xmlns:lticm"].should == "http://www.imsglobal.org/xsd/imslticm_v1p0"
      namespaces["xmlns:lticp"].should == "http://www.imsglobal.org/xsd/imslticp_v1p0"
      namespaces["xmlns:xsi"].should == "http://www.w3.org/2001/XMLSchema-instance"
    end

    it "has a title and description" do
      xml = get_xml
      title = xml.xpath('//blti:title')
      description = xml.xpath('//blti:description')
      title.should_not be_nil
      title.text.should_not be_nil
      title.text.length.should > 0
      description.should_not be_nil
      description.text.should_not be_nil
      description.text.length.should > 0
    end

    it "contains the correct launch url" do
      launch = get_xml.xpath('//blti:launch_url')
      launch.size.should == 1
      launch[0].text.should == "http://#{request.host}:#{request.port}#{lti_launch_path}"
    end

    it "contains the correct domain" do
      properties = get_xml.xpath('//blti:extensions/lticm:property')
      domain = properties.select { |p| p.attributes['name'].text == "domain" }
      domain.size.should == 1
      domain[0].text.should == request.host
    end

    it "contains the Canvas extension platform" do
      extensions = get_xml.xpath('//blti:extensions')
      platform = extensions.select { |e| e.attributes['platform'] }
      platform.size.should == 1
      platform[0].attributes['platform'].text.should == "canvas.instructure.com"
    end

    it "correctly defines an editor button" do
      options = get_xml.xpath('//blti:extensions/lticm:options')
      button = options.select { |o| o.attributes['name'].text == "editor_button" }
      button.size.should == 1
      [ "url", "icon_url", "text", "selection_width", "selection_height", "enabled" ].each do |prop|
        button[0].children.select { |p| "#{p['name']}" == prop}.size.should == 1
      end
    end

    it "requires the minimum necessary privacy permissions" do
      properties = get_xml.xpath('//blti:extensions/lticm:property')
      privacy = properties.select { |p| p.attributes['name'].text == "privacy_level" }
      privacy.size.should == 1
      privacy[0].text.should == "anonymous"
    end
  end

  context "LTI tool launch" do
    def get_launch_params
      { "context_id" => "contextid_123",
        "context_label" => "contextlabel_123",
        "context_title" => "Context Title",
        "ext_content_return_types" => "oembed,lti_launch_url,url,image_url,iframe",
        "ext_content_return_url" => "http://example.com/content_return_url",
        "roles" => "Instructor,urn:lti:instrole:ims/lis/Administrator",
        "user_id" => "userid_123"
      }
    end

    def assert_missing_field(name, params)
      response.status.should == 400
      JSON.parse(response.body).should == { "params" => params, "message" => "Required field #{name} not set" }
    end

    def launch_without_param(name)
      params = get_launch_params.except!(name)
      post :launch, params
      assert_missing_field(name, params)
      params[name] = ""
      post :launch, params
      assert_missing_field(name, params)
    end

    it "fails gracefully with missing or empty context id" do
      launch_without_param("context_id")
    end

    it "fails gracefully with missing or empty context label" do
      launch_without_param("context_label")
    end

    it "fails gracefully with missing or empty roles entry" do
      launch_without_param("roles")
    end

    it "fails gracefully with missing or empty user id" do
      launch_without_param("user_id")
    end

    it "fails gracefully with missing or empty return types" do
      launch_without_param("ext_content_return_types")
    end

    it "fails gracefully with missing or empty return URL" do
      launch_without_param("ext_content_return_url")
    end

    def check_bad_role_string(str)
      params = get_launch_params
      params["roles"] = str
      post :launch, params
      response.status.should == 400
      json = JSON.parse(response.body)
      json["params"].should == params
      json["message"].should match "Launch parameters must supply at least one role from \\[.*\\]"
    end

    it "fails gracefully with invalid roles entry" do
      check_bad_role_string("no_valid_roles")
      check_bad_role_string("urn:lti:instrole:ims/lis/Observer")
    end

    it "fails gracefully if iframe return type is not availble" do
      params = get_launch_params
      params["ext_content_return_types"] = "oembed,lti_launch_url,url,image_url"
      post :launch, params
      response.status.should == 400
      JSON.parse(response.body).should == { "params" => params, "message" => "ext_content_return_types must contain 'iframe'" }
    end

    def compare_session_to_param(param, session, params)
      session[param].should_not be_nil
      session[param].should == params["#{param}"]
    end

    it "sets required data in the session" do
      params = get_launch_params
      post :launch, params
      compare_session_to_param(:context_id, session, params)
      compare_session_to_param(:context_label, session, params)
      compare_session_to_param(:context_title, session, params)
      compare_session_to_param(:user_id, session, params)
      compare_session_to_param(:ext_content_return_url, session, params)
      [:instructor, :administrator].each do |role|
        session[:roles].include?(role).should be_true
      end
      [:oembed, :lti_launch_url, :url, :image_url, :iframe].each do |type|
        session[:ext_content_return_types].include?(type).should be_true
      end
    end

    def get_course_model()
      course = Course.new
      course.id = 42
      course.context_label = "Context Label"
      course.context_title = "Context Title"
      course
    end

    it "creates a new course object if not already present" do
      course = get_course_model
      Course.stub(:new).and_return(course)
      course.should_receive(:save)
      params = get_launch_params
      post :launch, params
    end

    it "loads existing course object if one exists" do
      params = get_launch_params
      course = get_course_model
      Course.stub(:find_by).and_return(course)
      Course.should_receive(:find_by).with( { :context_id => params["context_id"] })
      post :launch, params
    end

    it "redirects to the policy selection page" do
      course = get_course_model
      Course.stub(:new).and_return(course)
      Course.stub(:find_by).and_return(course)
      post :launch, get_launch_params
      response.should redirect_to(course_url(course))
    end

  end

end
