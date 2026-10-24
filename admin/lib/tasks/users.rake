namespace :users do
  desc "Crée ou met à jour un compte : bin/rails users:create EMAIL=… PASSWORD=… [ROLE=admin|accountant] [NAME=…]"
  task create: :environment do
    email, password = ENV.fetch("EMAIL"), ENV.fetch("PASSWORD")
    Current.actor_kind = "system"
    user = User.find_or_initialize_by(email_address: email.strip.downcase)
    user.update!(password:, role: ENV.fetch("ROLE", user.role || "admin"), name: ENV.fetch("NAME", user.name))
    puts "Compte #{user.email_address} (#{user.role_label}) prêt. Double authentification à configurer à la connexion." unless user.two_factor_enabled?
    puts "Compte #{user.email_address} (#{user.role_label}) mis à jour." if user.two_factor_enabled?
  end

  desc "Réinitialise la double authentification (téléphone perdu) : bin/rails users:reset_two_factor EMAIL=…"
  task reset_two_factor: :environment do
    Current.actor_kind = "system"
    user = User.find_by!(email_address: ENV.fetch("EMAIL").strip.downcase)
    user.reset_two_factor!
    puts "Double authentification de #{user.email_address} réinitialisée : à reconfigurer à la prochaine connexion."
  end
end
