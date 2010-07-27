class ApidocsController < ApplicationController

  skip_before_filter :login_required

  layout 'apidocs'

  before_filter :load_example_data

  def index
  end

  def concepts
  end

  protected

    def load_example_data
      @project = Project.first
      @user = User.first
    end

end