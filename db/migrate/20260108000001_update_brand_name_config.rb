class UpdateBrandNameConfig < ActiveRecord::Migration[7.0]
  def up
    config = InstallationConfig.find_or_initialize_by(name: 'BRAND_NAME')
    config.value = 'ChatMojo'
    config.save!
  end

  def down
    config = InstallationConfig.find_by(name: 'BRAND_NAME')
    config&.update(value: 'Chatwoot')
  end
end
