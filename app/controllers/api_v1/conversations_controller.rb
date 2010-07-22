class ApiV1::ConversationsController < ApiV1::APIController
  before_filter :load_conversation, :only => [:show,:update,:destroy,:watch,:unwatch]
  before_filter :check_permissions, :only => [:create,:update,:destroy,:watch,:unwatch]
  
  def index
    @conversations = @current_project.conversations
    
    respond_to do |f|
      f.json  { render :as_json => @conversations.to_xml(:root => 'conversations') }
    end
  end

  def show
    respond_to do |f|
      f.json  { render :as_json => @conversation.to_xml }
    end
  end
  
  def create
    @conversation = @current_project.new_conversation(current_user,params[:conversation])
    @conversation.body = params[:conversation][:body]
    @saved = @conversation.save
    
    if @saved
      if (params[:user_all] || 0).to_i == 1
        @conversation.add_watchers @current_project.users
      else
        add_watchers params[:user]
      end
      @conversation.notify_new_comment(@conversation.comments.first)
    end
    
    respond_to do |f|
      if @saved
        handle_api_success(f, @conversation, :is_new => true)
      else
        handle_api_error(f, @conversation)
      end
    end
  end
  
  def update
    @saved = @conversation.update_attributes(params[:task_list])
    
    respond_to do |f|
      if @saved
        handle_api_success(f, @conversation)
      else
        handle_api_error(f, @conversation)
      end
    end
  end

  def destroy
    @conversation.destroy
    respond_to do |f|
      handle_api_success(f, @conversation)
    end
  end
  
  def watch
    @conversation.add_watcher(current_user)
    respond_to do |f|
      handle_api_success(f, @conversation)
    end
  end

  def unwatch
    @conversation.remove_watcher(current_user)
    respond_to do |f|
      handle_api_success(f, @conversation)
    end
  end

  protected
  
  def load_conversation
    @conversation = @current_project.conversations.find(params[:id])
    return api_status(:not_found) if @conversation.nil?
  end
  
  def check_permissions
    unless (@conversation || @current_project).editable?(current_user)
      api_error(t('common.not_allowed'), :unauthorized)
      return false
    end
  end
  
end