class BackupJob < ApplicationJob
  queue_as :default

  def perform
    unless Backup.configured?
      Rails.logger.warn("[backup] skipped: BACKUP_* variables are not set")
      return
    end

    Current.actor_kind = "system"
    key = Backup.new.run
    Rails.logger.info("[backup] uploaded #{key}")
  end
end
