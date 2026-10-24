class AuditEventsController < ApplicationController
  PER_PAGE = 100

  def index
    @types = AuditEvent.distinct.order(:auditable_type).pluck(:auditable_type)
    @events = AuditEvent.recent.includes(:user)
    @events = @events.where(auditable_type: params[:type]) if params[:type].present?
    @events = @events.where(auditable_type: params[:type], auditable_id: params[:record_id]) if params[:record_id].present?
    @events = @events.where(user_id: params[:user_id]) if params[:user_id].present?
    @page = [ params[:page].to_i, 1 ].max
    @events = @events.offset((@page - 1) * PER_PAGE).limit(PER_PAGE + 1).to_a
    @next_page = @events.size > PER_PAGE
    @events = @events.first(PER_PAGE)
  end
end
