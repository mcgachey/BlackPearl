require 'spec_helper'

describe PolicyController do

  context "Create new policy" do
    it "fails gracefully if the user is not an instructor, designer or admin"
    it "fails gracefully if there is no policy parameter"
    it "fails gracefully if there is no title parameter"
    it "fails gracefully if there is no text parameter"
    it "fails gracefully if required parameters are missing from the session"
    it "creates policy model with the correct fields"
    it "doesn't set policy as public unless user is an admin"
    it "saves the policy"
    it "sets the new policy as selected for the current course"
    it "redirects to the course view page"
  end

  context "Update existing policy" do
    it "fails gracefully if the user is not an instructor, designer or admin"
    it "fails gracefully if there is no policy parameter"
    it "fails gracefully if the policy is not found"
    it "fails gracefully if there is no title, text or public parameter"
    it "doesn't set policy as public unless user is an admin"
    it "saves the policy"
    it "redirects to the view page for the current course if set"
    it "redirects to the view page for the policy if no course is set"
  end

  context "Show a policy" do
    it "fails gracefully if the policy is not found"
    it "loads the policy identified by the id parameter"
    it "doesn't prevent iframe for response"
  end

  context "Show new policy page" do
    it "fails gracefully if the user is not an instructor, designer or admin"
    it "doesn't prevent iframe for response"
  end

  context "Show a policy edit page" do
    it "fails gracefully if the policy is not found"
    it "loads the policy identified by the id parameter"
    it "doesn't prevent iframe for response"
  end

  context "Get the text for a policy" do
    it "fails gracefully if the policy is not found"
    it "returns the full text of the policy"
  end

end
