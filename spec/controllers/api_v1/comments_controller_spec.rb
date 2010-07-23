require 'spec_helper'

describe ApiV1::CommentsController do
  before do
    @user = Factory.create(:confirmed_user)
    @project = Factory.create(:project)
    @owner = @project.user
    @project.add_user(@user)
    @user2 = Factory.create(:confirmed_user)
    @project.add_user(@user2)
    @observer = Factory.create(:confirmed_user)
    @project.add_user(@observer)
    @project.people.last.update_attribute(:role, Person::ROLES[:observer])
    
    @comment = @project.new_comment(@user, @project, {:body => 'Something happened!'})
    @comment.save!
  end
  
  describe "#index" do
    it "shows comments in the project" do
      login_as @user2
      
      get :index, :project_id => @project.permalink
      response.should be_success
      
      JSON.parse(response.body)['comments'].length.should == 1
    end
  end
  
  describe "#show" do
    it "shows a comment" do
      login_as @user
      
      get :show, :project_id => @project.permalink, :id => @comment.id
      response.should be_success
      
      JSON.parse(response.body)['comment']['id'].should == @comment.id.to_s
    end
  end
  
  describe "#create" do
    it "should allow commenters to post a comment" do
      login_as @project.user
      
      post :create, :project_id => @project.permalink, :comment => {:body => 'Created!'}
      response.should be_success
      
      @project.comments(true).length.should == 2
    end
    
    it "should not allow observers to post a comment" do
      login_as @observer
      
      post :create, :project_id => @project.permalink, :comment => {:body => 'Created!'}
      response.status.should == '401 Unauthorized'
      
      @project.comments(true).length.should == 1
    end
  end
  
  describe "#update" do
    it "should allow the owner to modify a comment within 15 minutes" do
      login_as @user
      
      post :update, :project_id => @project.permalink, :id => @comment.id, :comment => {:body => 'Updated!'}
      response.should be_success
      
      @comment.update_attribute(:created_at, Time.now - 16.minutes)
      
      post :update, :project_id => @project.permalink, :id => @comment.id, :comment => {:body => 'Updated!'}
      response.status.should == '401 Unauthorized'
    end
    
    it "should not allow anyone else to modify another comment" do
      login_as @project.user
      
      post :update, :project_id => @project.permalink, :id => @comment.id, :comment => {:body => 'Updated!'}
      response.status.should == '401 Unauthorized'
    end
  end
  
  describe "#destroy" do
    it "should allow an admin to destroy a comment" do
      login_as @project.user
      
      post :destroy, :project_id => @project.permalink, :id => @comment.id
      response.should be_success
      
      @project.comments(true).length.should == 0
    end
    
    it "should allow the owner to destroy a comment" do
      login_as @user
      
      post :destroy, :project_id => @project.permalink, :id => @comment.id
      response.should be_success
      
      @project.comments(true).length.should == 0
    end
    
    it "should not allow a non-admin to destroy another comment" do
      login_as @user2
      
      post :destroy, :project_id => @project.permalink, :id => @comment.id
      response.status.should == '422 Unprocessable Entity'
      
      @project.comments(true).length.should == 1
    end
  end
end