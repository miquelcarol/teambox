class ApiV1::NotesController < ApiV1::APIController
  before_filter :load_page
  before_filter :load_note, :except => [:index,:create]
  before_filter :check_permissions, :only => [:create,:update,:destroy]
  
  def index
    @notes = @page.notes
    
    respond_to do |f|
      f.json{ render :as_json => @notes.to_xml(:root => 'notes') }
    end
  end

  def show
    respond_to do |f|
      f.json{ render :as_json => @note.to_xml }
    end
  end
  
  def create
    calculate_position
    
    @note = @page.build_note(params[:note])
    @note.updated_by = current_user
    save_slot(@note) if @note.save
    
    respond_to do |f|
      if !@note.new_record?
        handle_api_success(f, @note, :is_new => true)
      else
        handle_api_error(f, @note)
      end
    end
  end
  
  def update
    @note.updated_by = current_user
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