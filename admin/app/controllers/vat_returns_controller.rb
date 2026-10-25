# Quarterly VAT returns. The accountant files them in Intervat and closes the quarter here (her one write right).
class VatReturnsController < ApplicationController
  allow_read_only_writes only: :close
  before_action :set_vat_return, except: :index

  def index
    first = VatReturn::Quarter.containing(CompanyProfile.current.vat_tracked_since || Date.current)
    current = VatReturn::Quarter.containing(Date.current)
    quarters = [ first ]
    quarters << quarters.last.next while quarters.last.starts_on < current.starts_on
    @vat_returns = quarters.reverse.map { |quarter| VatReturn.new(quarter) }
  end

  def show
  end

  def close
    if @vat_return.closable?
      @vat_return.close!(user: Current.user)
      redirect_to vat_return_path(@vat_return.quarter.to_param), notice: "#{@vat_return.quarter.label} clôturé. Les pièces de ce trimestre ne peuvent plus changer."
    else
      redirect_to vat_return_path(@vat_return.quarter.to_param), alert: "Ce trimestre ne peut pas encore être clôturé."
    end
  end

  def export
    export = AccountantExport.new(@vat_return)
    send_data export.render, filename: export.filename, type: "application/zip"
  end

  def declaration
    xml = IntervatXml.new(@vat_return)
    send_data xml.declaration, filename: xml.filename("intervat"), type: "application/xml"
  end

  def listing
    xml = IntervatXml.new(@vat_return)
    send_data xml.intracom_listing, filename: xml.filename("listing-intracom"), type: "application/xml"
  end

  private
    def set_vat_return
      quarter = VatReturn::Quarter.parse(params[:id]) or raise ActiveRecord::RecordNotFound
      @vat_return = VatReturn.new(quarter)
    end
end
