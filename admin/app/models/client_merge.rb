# Merges a duplicate client into the one we keep: everything the duplicate owns (contacts, projects,
# time entries, contracts, packs, invoices, comments) moves to the kept client, blank details of the kept
# client are filled from the duplicate, then the duplicate is deleted. All in one transaction, every
# change recorded in the audit log.
class ClientMerge
  class Error < ArgumentError; end

  FILLED_ATTRIBUTES = %w[ vat_number street postal_code city billing_email peppol_id hourly_rate harvest_id ].freeze

  attr_reader :kept, :duplicate, :moved

  def initialize(kept:, duplicate:)
    @kept = kept
    @duplicate = duplicate
    @moved = {}
  end

  # What the merge will move, by association, for a confirmation message.
  def preview
    { contacts: duplicate.contacts.size, projects: duplicate.projects.size, time_entries: duplicate.time_entries.size,
      contracts: duplicate.contracts.size, packs: duplicate.packs.size, invoices: duplicate.invoices.size,
      comments: duplicate.comments.size }
  end

  def merge!
    raise Error, "Choisis un autre client à fusionner." if duplicate.nil? || duplicate.id == kept.id

    Client.transaction do
      fill_blank_details
      move_contacts
      %i[ projects contracts packs invoices time_entries ].each { |association| move(association) }
      move_comments
      duplicate.reload.destroy!
    end
    self
  end

  private
    def fill_blank_details
      details = FILLED_ATTRIBUTES.select { |name| kept[name].blank? && duplicate[name].present? }.index_with { |name| duplicate[name] }
      notes = [ kept.notes, duplicate.notes.presence && "Notes de #{duplicate.name} :\n#{duplicate.notes}" ].compact_blank.join("\n\n")
      details["notes"] = notes if notes != kept.notes.to_s
      # harvest_id is unique: release it on the duplicate before giving it to the kept client.
      duplicate.update!(harvest_id: nil) if details.key?("harvest_id")
      kept.update!(details) if details.any?
    end

    # The kept client keeps its own primary contact when it has one.
    def move_contacts
      demote = kept.contacts.exists?(primary: true)
      records = duplicate.contacts.to_a
      records.each { |contact| contact.update!(client: kept, primary: demote ? false : contact.primary) }
      moved[:contacts] = records.size
    end

    # Records are saved one by one (not update_all) so that each move lands in the audit log.
    # Time entries are moved last: their validation checks that project and pack belong to the same client.
    def move(association)
      records = duplicate.public_send(association).to_a
      records.each do |record|
        record.reassigning_client = true if record.respond_to?(:reassigning_client=)
        record.update!(client: kept)
      end
      moved[association] = records.size
    end

    def move_comments
      records = duplicate.comments.to_a
      records.each { |comment| comment.update!(commentable: kept) }
      moved[:comments] = records.size
    end
end
