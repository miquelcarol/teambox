class ApiV1::UploadsController < ApiV1::APIController
  before_filter :load_upload, :only => [:update,:show,:destroy]
  before_filter :check_permissions, :only => [:create,:update,:destroy]
  
  def index
    @uploads = @current_project.uploads.all(:conditions => api_range, :limit => api_limit)
    
    respond_to do |f|
      f.json { render :as_json => @uploads.to_xml(:root => 'uploads') }
    end
  end

  def show
    respond_to do |f|
      f.json  { render :as_json => @upload.to_xml }
    end
  end
  
  def create
    @upload = @current_project.uploads.new params[:upload]
    @upload.user = current_user
    calculate_position if @upload.page
    @page = @upload.page

    if @upload.save
      @current_project.log_activity(@upload, 'create')
      save_slot(@upload) if @upload.page
    end

    respond_to do |f|
      if !@upload.new_record?
        handle_api_success(f, @upload, :is_new => true)
      else
        handle_api_error(f, @upload)
      end
    end
  end

  def destroy
    @upload.destroy
    
    respond_to do |f|
      handle_api_success(f, @upload)
    end
  end

  protected
  
  def load_upload
    @upload = @current_project.uploads.find(params[:id])
    return api_status(:not_found) if @upload.nil?
  end
  
end