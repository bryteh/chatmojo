class ReplaceChatwootInEmailTemplates < ActiveRecord::Migration[7.0]
  def up
    EmailTemplate.find_each do |template|
      if template.body&.include?('Chatwoot')
        new_body = template.body.gsub('Chatwoot', 'ChatMojo')
        template.update_attribute(:body, new_body)
      end
    end
  end

  def down
    EmailTemplate.find_each do |template|
      if template.body&.include?('ChatMojo')
        new_body = template.body.gsub('ChatMojo', 'Chatwoot')
        template.update_attribute(:body, new_body)
      end
    end
  end
end
