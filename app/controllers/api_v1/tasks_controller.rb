class ApiV1::TasksController < ApiV1::APIController
  before_filter :load_task_list
  before_filter :load_task, :except => [:index, :create]
  before_filter :check_permissions, :except => [:index, :show]
  
  def index
    if @current_project
      @tasks = (@task_list || @current_project).tasks.all(:conditions => api_range, :limit => api_limit)
    else
      @tasks = Task.find_all_by_project_id(current_user.project_ids, :conditions => api_range)
    end
    
    respond_to do |f|
      f.json  { render :as_json => @tasks.to_xml(:root => 'tasks') }
    end
  end

  def show
    respond_to do |f|
      f.json  { render :as_json => @task.to_xml }
    end
  end
  
  def create
    if @task = @current_project.create_task(current_user,@task_list,params[:task])
      unless @task.new_record?
        @comment = @current_project.new_task_comment(@task)
        @task.reload
      end
    end
    
    respond_to do |f|
      if !@task.new_record?
        handle_api_success(f, @task, :is_new => true)
      else
        handle_api_error(f, @task)
      end
    end
  end
  
  def update
    @saved = @task.update_attributes(params[:task])
    
    respond_to do |f|
      if @saved
        handle_api_success(f, @task)
      else
        handle_api_error(f, @task)
      end
    end
  end

  def destroy
    @task.destroy
    respond_to do |f|
      handle_api_success(f, @task)
    end
  end

  def watch
    @task.add_watcher(current_user)
    respond_to do |f|
      handle_api_success(f, @task)
    end
  end

  def unwatch
    @task.remove_watcher(current_user)
    respond_to do |f|
      handle_api_success(f, @task)
    end
  end
  
  def reorder
    moved_task_ids = new_task_ids_for_task_list.to_set - @task_list.task_ids.to_set
    moved_task_ids.each do |moved_task_id|
      Task.find(moved_task_id).update_attribute(:task_list, @task_list)
    end
    new_task_ids_for_task_list.each_with_index do |task_id,idx|
      task = @task_list.tasks.find(task_id)
      task.update_attribute(:position,idx.to_i)
    end
    
    api_status(:ok)
  end

  protected
  
  def load_task
    if @current_project
      @task = (@task_list || @current_project).tasks.find(params[:id]) rescue nil
    else
      @task = Task.find(params[:id], :conditions => {:project_id => current_user.project_ids})
    end
    return api_status(:not_found) if @task.nil?
  end
  
  def check_permissions
    # Can they even edit the project?
    unless @current_project.editable?(current_user)
      api_error(t('common.not_allowed'), :unauthorized)
      return false
    end
  end
end