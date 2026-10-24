# Shared bookkeeping of the history imports: counts, warnings, client matching, dry runs.
class HistoryImport
  class DryRun < StandardError; end

  def initialize(dry_run: false)
    @dry_run = dry_run
    @counts = Hash.new { |hash, key| hash[key] = Hash.new(0) }
    @warnings = []
  end

  def run
    previous_actor = Current.actor_kind
    Current.actor_kind = "system"
    ActiveRecord::Base.transaction do
      import
      raise DryRun if @dry_run
    end
    report
  rescue DryRun
    "Simulation (rien n'a été enregistré)\n#{report}"
  ensure
    Current.actor_kind = previous_actor
  end

  private
    def import = raise(NotImplementedError)

    def count(record, label)
      @counts[label][record.previously_new_record? ? :added : :updated] += 1
    end

    def skip(label) = @counts[label][:skipped] += 1

    def warn(message) = @warnings << message

    def report
      lines = [ "Import terminé :" ] + @counts.sort.map do |what, count|
        "  #{what} : #{count[:added]} ajout(s), #{count[:updated]} mise(s) à jour#{", #{count[:skipped]} ignoré(s)" if count[:skipped].positive?}"
      end
      lines += [ "", "À vérifier :" ] + @warnings.uniq.first(200).map { "  - #{_1}" } if @warnings.any?
      lines.join("\n")
    end

    # Clients are matched by name, ignoring case and accents; unknown ones are created as former clients.
    def find_or_create_client(name, **attributes)
      key = normalize(name)
      @clients_by_name ||= Client.all.index_by { |client| normalize(client.name) }
      @clients_by_name[key] ||= Client.create!(name: name.strip, kind: "organisation", status: "ancien", **attributes).tap do |client|
        count(client, "Clients")
        warn "Client créé : #{client.name} (vérifie s'il ne fait pas doublon)"
      end
    end

    def normalize(name) = I18n.transliterate(name.to_s).downcase.gsub(/[^a-z0-9]/, "")

    # "1 234,56" / "1.234,56" / "1234.56" / "-50" → BigDecimal
    def parse_amount(value)
      text = value.to_s.strip.delete("  €")
      return nil if text.empty?
      text = text.delete(".").tr(",", ".") if text.include?(",")
      BigDecimal(text)
    rescue ArgumentError
      nil
    end

    def parse_date(value)
      text = value.to_s.strip
      return nil if text.empty?
      Date.strptime(text, text.include?("/") ? "%d/%m/%Y" : "%Y-%m-%d")
    rescue Date::Error
      Date.parse(text) rescue nil
    end
end
