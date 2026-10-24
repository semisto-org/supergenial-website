class DependencesController < ApplicationController
  def show
    @dependence = SupplierDependence.new
  end
end
