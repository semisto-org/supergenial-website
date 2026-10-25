# Reads a purchase document with Claude and prefills the purchase.
class PurchaseExtractionJob < ApplicationJob
  queue_as :default

  def perform(purchase, extraction: nil)
    return unless purchase.document.attached?
    data = (extraction || PurchaseExtraction.new).call(purchase.document.download, content_type: purchase.document.blob.content_type)
    purchase.apply_extraction(data)
    purchase.update!(extraction_status: "done", extraction_error: nil)
  rescue PurchaseExtraction::Error, ActiveRecord::RecordInvalid => error
    purchase.reload.update!(extraction_status: "failed", extraction_error: error.message)
  end
end
