# Bank statements imported from CODA files (Belfius: Belfius Web → Extraits → CODA).
class BankStatementsController < ApplicationController
  MAX_FILE_SIZE = 5.megabytes

  def index
    @bank_statements = BankStatement.recent.includes(:transactions).limit(60)
    @unmatched_count = BankTransaction.unmatched.count
  end

  def show
    @bank_statement = BankStatement.find(params[:id])
  end

  def create
    file = params[:file]
    return redirect_to(bank_statements_path, alert: "Choisis un fichier CODA.") unless file.respond_to?(:read)
    return redirect_to(bank_statements_path, alert: "Fichier trop lourd (5 Mo maximum).") if file.size > MAX_FILE_SIZE

    result = CodaImport.new(file.read, filename: file.original_filename).run
    notice = "#{result.statements.size} extrait(s) importé(s), #{result.matched} mouvement(s) rapproché(s) automatiquement."
    notice += " #{result.skipped} extrait(s) déjà importé(s), ignoré(s)." if result.skipped.positive?
    redirect_to bank_transactions_path(status: "unmatched"), notice:
  rescue CodaParser::Error => error
    redirect_to bank_statements_path, alert: "Import impossible : #{error.message}"
  end

  def file
    blob = BankStatement.find(params[:id]).file.blob
    send_data blob.download, filename: blob.filename.to_s, type: "text/plain", disposition: "attachment"
  end

  def destroy
    statement = BankStatement.find(params[:id])
    statement.transactions.each { |transaction| transaction.unmatch! if transaction.matched? }
    statement.destroy
    redirect_to bank_statements_path, notice: "#{statement} supprimé.", status: :see_other
  end
end
