require 'spec_helper'

describe ApiV1::CommentsController do
  before do
    make_a_typical_project
    
    @comment = @project.new_comment(@user, @project, {:body => 'Something happened!'})
    @comment.save!
  end
  
  describe "#index" do
    it "shows comments in the project" do
      login_as @user
      
      get :index, :project_id => @project.permalink
      response.should be_success
      
      JSON.parse(response.body)['comments'].length.should == 1
    end
    
    it "limits and offsets comments" do
      login_as @user
      
      other_comment = @project.new_comment(@user, @project, {:body => 'Something else happened!'})
      other_comment.save!
      
      get :index, :project_id => @project.permalink, :since_id => @project.comment_ids[1], :count => 1
      response.should be_success
      
      JSON.parse(response.body)['comments'].map{|a| a['id'].to_i}.should == [@project.reload.comment_ids[0]]
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
      
      put :update, :project_id => @project.permalink, :id => @comment.id, :comment => {:body => 'Updated!'}
      response.should be_success
      
      @comment.update_attribute(:created_at, Time.now - 16.minutes)
      
      put :update, :project_id => @project.permalink, :id => @comment.id, :comment => {:body => 'Updated FAIL!'}
      response.status.should == '401 Unauthorized'
    end
    
    it "should not allow anyone else to modify another comment" do
      login_as @project.user
      
      put :update, :project_id => @project.permalink, :id => @comment.id, :comment => {:body => 'Updated!'}
      response.status.should == '401 Unauthorized'
    end
  end
  
  describe "#destroy" do
    it "should allow an admin to destroy a comment" do
      login_as @project.user
      
      put :destroy, :project_id => @project.permalink, :id => @comment.id
      response.should be_success
      
      @project.comments(true).length.should == 0
    end
    
    it "should allow the owner to destroy a comment" do
      login_as @user
      
      put :destroy, :project_id => @project.permalink, :id => @comment.id
      response.should be_success
      
      @project.comments(true).length.should == 0
    end
    
    it "should not allow a non-admin to destroy another comment" do
      login_as @observer
      
      put :destroy, :project_id => @project.permalink, :id => @comment.id
      response.status.should == '422 Unprocessable Entity'
      
      @project.comments(true).length.should == 1
    end
  end
end