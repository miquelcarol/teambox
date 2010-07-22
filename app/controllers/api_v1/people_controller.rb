class ApiV1::PeopleController < ApiV1::APIController
  before_filter :load_person, :except => [:index]
  before_filter :check_permissions, :only => [:update]
  
  def index
    @people = @current_project.people
    
    respond_to do |f|
      f.json  { render :as_json => @people.to_xml(:root => 'people') }
    end
  end

  def show
    respond_to do |f|
      f.json  { render :as_json => @person.to_xml }
    end
  end
  
  def update
    respond_to do |f|
      if !@current_project.owner?(@person.user) && @person.update_attributes(params[:person])
        handle_api_success(f, @person)
      else
        handle_api_error(f, @person)
      end
    end
  end

  def destroy
    has_permission = !@current_project.owner?(@person.user) && ((current_user == @person.user) or @current_project.admin?(current_user))
    if has_permission
      @person.destroy
    end
    respond_to do |f|
      if has_permission
        handle_api_success(f,@person)
      else
        handle_api_error(f, @person, :status => :unauthorized)
      end
    end
  end

  protected
  
  def load_person
    @person = @current_project.people.find params[:id]
    return api_status(:not_found) if @person.nil?
  end
  
  def check_permissions
    unless @current_project.admin?(current_user)
      api_error("You don't have permission to administer within \"#{@current_project.name}\" project", :unauthorized)
    end
  end
  
end