class ApiV1::DividersController < ApiV1::APIController
  before_filter :load_page
  before_filter :load_divider, :except => [:index,:create]
  before_filter :check_permissions, :only => [:create,:update,:destroy]
  
  def index
    @dividers = @page.dividers
    
    respond_to do |f|
      f.json{ render :as_json => @dividers.to_xml(:root => 'dividers') }
    end
  end

  def show
    respond_to do |f|
      f.json{ render :as_json => @divider.to_xml }
    end
  end
  
  def create
    calculate_position
    
    @divider = @page.build_divider(params[:divider])
    @divider.updated_by = current_user
    save_slot(@divider) if @divider.save
    
    respond_to do |f|
      if !@divider.new_record?
        handle_api_success(f, @divider, :is_new => true)
      else
        handle_api_error(f, @divider)
      end
    end
  end
  
  def update
    @divider.updated_by = current_user
    respond_to do |f|
      if @divider.update_attributes(params[:divider])
        handle_api_success(f, @divider)
      else
        handle_api_error(f, @divider)
      end
    end
  end

  def destroy
    @divider.destroy
    respond_to do |f|
      handle_api_success(f,@divider)
    end
  end

  protected
  
  def load_divider
    @divider = @page.dividers.find params[:id]
    return api_status(:not_found) if @divider.nil?
  end
  
end