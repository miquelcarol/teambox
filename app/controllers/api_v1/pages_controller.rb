class ApiV1::PagesController < ApplicationController
  before_filter :load_page, :only => [:show, :update, :reorder, :destroy]
  before_filter :check_permissions, :only => [:create,:update,:reorder,:destroy]
  
  def index
    if @current_project
      @pages = @current_project.pages
    else
      @pages = current_user.projects.collect { |p| p.pages }
    end
    
    respond_to do |f|
      f.json{ render :as_json => @pages.to_xml(:include => :slots, :root => 'pages') }
    end
  end
  
  def create
    @page = @current_project.new_page(current_user,params[:page])    
    respond_to do |f|
      if @page.save
        handle_api_success(f, @page, true)
      else
        handle_api_error(f, @page)
      end
    end
  end
    
  def show
    respond_to do |f|
      f.json{ render :as_json => @page.to_xml(:include => [:slots, :objects]) }
    end
  end
  
  def update
    respond_to do |f|
      if @page.update_attributes(params[:page])
        handle_api_success(f, @page)
      else
        handle_api_error(f, @page)
      end
    end
  end
  
  def reorder
    order = params[:slots].collect { |id| id.to_i }
    current = @page.slots.map { |slot| slot.id }
    
    # Handle orphaned elements
    orphans = (current - order).map { |o| 
      idx = current.index(o)
      oid = idx == 0 ? -1 : current[idx-1]
      [@page.slots[idx], oid]
    }
    
    # Insert orphans back into order list
    orphans.each { |o| order.insert(o[1], (order.index(o[0]) || -1)+1) }
    
    @page.slots.each do |slot|
      slot.position = order.index(slot.id)
      slot.save!
    end
    
    respond_to do |f|
      handle_api_success(f, @page)
    end
  end

  def destroy
    @page.destroy

    respond_to do |f|
      handle_api_success(f, @page)
    end
  end

  protected
    def load_page
      @page = @current_project.pages.find params[:id]
      return api_status(:not_found) if @page.nil?
    end
    
end