require 'spec_helper'
require 'nokogiri'

describe LtiController do

  context "Service definition XML" do
    it "uses the LTI namespaces"
    it "has a title and description"
    it "contains the correct launch url"
    it "contains the correct domain"
    it "contains the Canvas extension platform"
    it "correctly defines an editor button"
    it "requires the minimum necessary privacy permissions"
  end

  context "LTI tool launch" do

    it "launches with minimal parameters"
    it "fails gracefully with missing or empty context id"
    it "fails gracefully with missing or empty context label"
    it "fails gracefully with missing or empty roles entry"
    it "fails gracefully with incorrectly formatted roles entry"
    it "fails gracefully with missing or empty user id"
    it "fails gracefully with missing or empty return URL"
    it "doesn't prevent iframe for response"
    it "sets required data in the session"
    it "guarantees a database entry for the course"
    it "redirects to the policy selection page"

  end

end
