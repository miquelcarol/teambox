class ApiV1::NotesController < ApiV1::APIController
  before_filter :load_page
  before_filter :load_note, :except => [:index]
  before_filter :check_permissions, :only => [:create,:update,:destroy]
  
  def index
    @notes = @page.notes
    
    respond_to do |f|
      f.json{ render :as_json => @notes.to_xml(:root => 'notes') }
    end
  end

  def show
    respond_to do |f|
      f.json{ render :as_json => @page.to_xml(:include => [:slots, :objects]) }
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
    respond_to do |f|
      if @note.update_attributes(params[:note])
        handle_api_success(f, @note)
      else
        handle_api_error(f, @note)
      end
    end
  end

  def destroy
    @note.destroy
    respond_to do |f|
      handle_api_success(f,@note)
    end
  end

  protected
  
  def load_note
    @note = @page.notes.find params[:id]
    return api_status(:not_found) if @note.nil?
  end
  
end