require 'spec_helper'

describe ApiV1::UsersController do
  before do
    @user = Factory.create(:confirmed_user)
    @fred = Factory.create(:confirmed_user)
    @project = Factory.create(:project)
    @owner = @project.user
    @project.add_user(@user)
  end
  
  describe "#show" do
    it "shows a user by name" do
      login_as @user
      
      get :show, :id => @project.user.login
      response.should be_success
      
      JSON.parse(response.body)['id'].to_i.should == @project.user.id
    end
    
    it "shows a user by id" do
      login_as @user
      
      get :show, :id => @project.user.id
      response.should be_success
      
      JSON.parse(response.body)['id'].to_i.should == @project.user.id
    end
    
    it "does not show a user not known to the current user" do
      login_as @user
      
      get :show, :id => @fred.login
      response.status.should == '401 Unauthorized'
    end
  end
end