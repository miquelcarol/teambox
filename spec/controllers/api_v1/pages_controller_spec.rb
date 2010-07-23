require 'spec_helper'

describe ApiV1::PagesController do
  before do
    @user = Factory.create(:confirmed_user)
    @project = Factory.create(:project)
    @owner = @project.user
    @project.add_user(@user)
    @observer = Factory.create(:confirmed_user)
    @project.add_user(@observer)
    @project.people.last.update_attribute(:role, Person::ROLES[:observer])
    
    @page = @project.new_page(@user, {:name => 'Important plans!'})
    @page.save!
  end
  
  describe "#index" do
    it "shows pages in the project" do
      login_as @user
      
      get :index, :project_id => @project.permalink
      response.should be_success
      
      JSON.parse(response.body)['pages'].length.should == 1
    end
  end
  
  describe "#show" do
    it "shows a page" do
      login_as @user
      
      get :show, :project_id => @project.permalink, :id => @page.id
      response.should be_success
      
      JSON.parse(response.body)['page']['id'].should == @page.id.to_s
    end
  end
  
  describe "#update" do
    it "should allow participants to modify the page" do
    end
    
    it "should not allow non-participants to modify the page" do
    end
  end
  
  describe "#destroy" do
    it "should allow participants to destroy the page" do
    end
    
    it "should not allow non-participants to destroy the page" do
    end
  end
end