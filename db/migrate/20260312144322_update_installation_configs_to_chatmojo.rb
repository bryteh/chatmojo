class UpdateInstallationConfigsToChatmojo < ActiveRecord::Migration[7.0]
  def up
    InstallationConfig.find_by(name: 'INSTALLATION_NAME')&.update!(value: 'Chatmojo')
    InstallationConfig.find_by(name: 'BRAND_NAME')&.update!(value: 'Chatmojo')
  end

  def down
    InstallationConfig.find_by(name: 'INSTALLATION_NAME')&.update!(value: 'Chatwoot')
    InstallationConfig.find_by(name: 'BRAND_NAME')&.update!(value: 'Chatwoot')
  end
end
