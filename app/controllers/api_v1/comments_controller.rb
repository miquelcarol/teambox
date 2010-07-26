class ApiV1::CommentsController < ApiV1::APIController
  before_filter :load_comment, :only => [:update, :convert, :show, :destroy]
  before_filter :load_target, :only => [:index, :create, :convert]
  before_filter :check_timeless, :only => [:convert]
  before_filter :check_permissions, :only => [:create, :update, :convert]
  
  def index
    @comments = @target.comments.all(:conditions => api_range, :limit => api_limit)
    
    api_respond @comments.to_xml(:root => 'comments')
  end

  def show
    api_respond @comment.to_xml
  end
  
  def create
    owner = params.has_key?(:project_id) ? @current_project : current_user
    @comment = owner.new_comment(current_user,@target,params[:comment])

    # If this is a status update, we'll turn it in a new `simple` Conversation
    if @comment.target.is_a?(Project)
      @conversation = @current_project.new_conversation(current_user, :simple => true )
      @conversation.body = @comment.body
      if @conversation.save
        comment = @conversation.comments.last
        comment.uploads = @comment.uploads
        @saved = comment.save
        @comment = comment
      else
        @comment.errors.add(:body, :no_body_generic)
      end
    else
      @saved = @comment.save
    end

    if @saved
      handle_api_success(@conversation || @comment, :is_new => true)
    else
      handle_api_error(@conversation || @comment)
    end
  end
  
  def update
    @has_permission and @saved = @comment.update_attributes(params[:comment])
    
    if @saved
      handle_api_success(@comment)
    else
      handle_api_error(@comment)
    end
  end

  def destroy
    @has_permission = if @comment.can_destroy?(current_user)
      @comment.destroy
      true
    else  
      false
    end
    
    if @has_permission
      handle_api_success(@comment)
    else
      handle_api_error(@comment)
    end
  end
  
  def convert
    # !!!
  end

  protected

    def load_comment
      @comment = @current_project.comments.find params[:id]
      api_status(:not_found) unless @comment
    end

    def load_target
      @target = if params.has_key?(:project_id)
        assign_project_target
      else
        User.find(params[:user_id])
      end
    end
    
    def check_timeless
      if (action_name == 'edit' && params[:part] == 'task') || action_name == 'convert'
        @checks_time = false
      end
    end
    
    def check_permissions
      # Can they even create comments?
      if @comment
        @has_permission = true
        @checks_time = @checks_time.nil?
        
        if action_name == 'destroy'
          return if @comment.can_destroy?(current_user, @checks_time)
        elsif action_name == 'convert'
          return if @current_project.editable?(current_user)
        else
          return if @comment.can_edit?(current_user, @checks_time)
        end
        
        # Error update handled in rjs handlers
        @has_permission = false
        return if request.format == :js
        
        # Process of elimination: don't allow this!
        api_error(t('comments.errors.cannot_update'), :unauthorized)
      else
        unless @current_project.commentable?(current_user)
          api_error(t('common.not_allowed'), :unauthorized)
        end
      end
    end

    def assign_project_target
      if params.has_key?(:task_id)
        t = @current_project.tasks.find(params[:task_id])
        t.previous_status = t.status
        t.previous_assigned_id = t.assigned_id
        t.status = params[:comment][:status]
        if params[:comment][:target_attributes]
          t.assigned_id = params[:comment][:target_attributes][:assigned_id]
        end
        t
      elsif params.has_key?(:task_list_id)
        @current_project.task_lists.find(params[:task_list_id])
      elsif params.has_key?(:conversation_id)
        @current_project.conversations.find(params[:conversation_id])
      else
        @current_project
      end
    end
  
end