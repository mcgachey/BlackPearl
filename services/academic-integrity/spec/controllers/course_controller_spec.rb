require 'spec_helper'

describe CourseController do

  context "Show course screen" do
    it "fails gracefully if the course does not exist"
    it "finds the correct policy for the course"
    it "doesn't find a policy if one is not set"
    it "sets the instructor flag if the user has that role"
    it "does not set the instructor flag if the user doesn't have that role"
  end

  context "Show edit screen" do
    it "fails gracefully if the user is not an instructor, designer or admin"
    it "fails gracefully if the course does not exist"
    it "finds the correct policy for the course"
    it "doesn't find a policy if one is not set"
    it "lists all policies visible to the current user"
    it "doesn't list policies that are not visible to the current user"
  end

  context "Update selected policy for course" do
    it "fails gracefully if the user is not an instructor, designer or admin"
    it "fails gracefully if the course does not exist"
    it "fails gracefully if there is no course parameter"
    it "fails gracefully if there is no policy ID parameter"
    it "fails gracefully if the selected policy does not exist"
    it "sets the selected policy ID in the course"
    it "saves the updated course"
    it "redirects to the course page"
  end

  context "Return control to LMS" do
    it "fails gracefully if the user is not an instructor, designer or admin"
    it "fails gracefully if the course does not exist"
    it "returns without data if no course is selected"
    it "redirects to the session redirect URL if a course is selected"
    it "passes a URL-encoded JSON structure to the redirect URL"
    it "passes an iframe return type to the redirect URL"
    it "passes the URL of the course view page to the redirect URL"
    it "properly appends the query string to a URL containing a query"
  end

end
