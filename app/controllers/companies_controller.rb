class CompaniesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]
  skip_before_action :set_current_company, only: [:index]
  
  def index
    @companies = Company.all
  end
end
