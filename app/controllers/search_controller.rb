class SearchController < ApplicationController

  skip_before_filter :load_project
  before_filter :load_project_search, :only => :results
  before_filter :permission_to_search, :only => :results

  def results
    @search = params[:search]

    unless @search.blank?
      @comments = Comment.search @search,
        :retry_stale => true, :order => 'created_at DESC',
        :with => { :project_id => project_ids },
        :page => params[:page]
    end
  end
  
  protected

    def load_project_search
      @current_project = Project.find_by_permalink(params[:project_id]) if params[:project_id]
    end

    def permission_to_search
      unless user_can_search? or (@current_project and project_owner.can_search?)
        flash[:notice] = "Search is disabled"
        redirect_to root_path
      end
    end
    
    def user_can_search?
      current_user.can_search?
    end
    
    def project_owner
      @current_project.user
    end
  
    def project_ids
      if @current_project
        @current_project.id
      else
        current_user.projects.collect { |p| p.id }
      end
    end

end
