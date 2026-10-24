# Comments on any commentable record. Open to the accountant, who cannot edit otherwise.
class CommentsController < ApplicationController
  COMMENTABLE_TYPES = [ Client, Project, Contract, Invoice, FixedCost, Plan, Supplier, ExpenseCategory ].index_by(&:name).freeze

  allow_read_only_writes

  def create
    model = COMMENTABLE_TYPES[params[:commentable_type]] or return head(:unprocessable_entity)
    commentable = model.find(params[:commentable_id])

    comment = commentable.comments.new(body: params.dig(:comment, :body))
    if comment.save
      redirect_back_or_to root_path, notice: "Commentaire ajouté."
    else
      redirect_back_or_to root_path, alert: "Le commentaire est vide."
    end
  end

  def update
    comment = Comment.find(params[:id])
    comment.update!(resolved_at: comment.resolved? ? nil : Time.current)
    redirect_back_or_to root_path
  end

  def destroy
    comment = Current.user.admin? ? Comment.find(params[:id]) : Comment.where(user: Current.user).find(params[:id])
    comment.destroy
    redirect_back_or_to root_path, notice: "Commentaire supprimé.", status: :see_other
  end
end
