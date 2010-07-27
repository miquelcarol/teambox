class ApidocsController < ApplicationController

  skip_before_filter :login_required

  layout 'apidocs'

  before_filter :load_example_data

  def index
  end

  def concepts
  end

  def model
    unless params[:model].match /\A[\w_]+\z/ # safe
      render :text => "Invalid model"
      return
    end
    @model = eval(params[:model].camelize)
  end

  protected

    def load_example_data
      @project = Project.first
      @user = User.first
    end

end