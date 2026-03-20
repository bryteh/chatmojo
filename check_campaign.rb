account = Account.first
puts "Account 1 whatsapp_campaign enabled? #{account.feature_enabled?(:whatsapp_campaign)}"
Campaign.where(campaign_type: :one_off).each do |c|
  puts "Campaign #{c.id} - Status: #{c.campaign_status} - Inbox: #{c.inbox.inbox_type} - scheduled_at: #{c.scheduled_at}"
  if c.inbox.inbox_type == 'Whatsapp'
    puts "  Provider: #{c.inbox.channel.provider}"
    puts "  Labels: #{c.audience}"
  end
end
