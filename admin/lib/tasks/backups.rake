namespace :backups do
  desc "Lance une sauvegarde hors site maintenant"
  task run: :environment do
    BackupJob.perform_now
  end

  desc "Déchiffre une sauvegarde téléchargée : bin/rails backups:decrypt FILE=…tar.gz.enc [OUT=…tar.gz]"
  task decrypt: :environment do
    file = ENV.fetch("FILE")
    out = ENV.fetch("OUT", file.delete_suffix(".enc"))
    File.binwrite(out, Backup.decrypt(File.binread(file), ENV.fetch("BACKUP_ENCRYPTION_KEY")))
    puts "Écrit #{out}"
  end
end
