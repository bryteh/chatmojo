require 'csv'

class Contacts::ExportService
  pattr_initialize [:account!, :account_user!, :params, :column_names]

  def perform
    CSV.generate do |csv|
      headers = valid_headers(column_names)
      csv << headers
      contacts.each do |contact|
        csv << headers.map do |header|
          if header == 'labels'
            contact.labels.pluck(:title).join(', ')
          else
            contact.send(header)
          end
        end
      end
    end
  end

  private

  def contacts
    if params.present? && params[:payload].present? && params[:payload].any?
      result = ::Contacts::FilterService.new(account, account_user, params).perform
      result[:contacts]
    elsif params[:label].present?
      account.contacts.resolved_contacts(use_crm_v2: account.feature_enabled?('crm_v2')).tagged_with(params[:label], any: true)
    else
      account.contacts.resolved_contacts(use_crm_v2: account.feature_enabled?('crm_v2'))
    end
  end

  def valid_headers(column_names)
    available_columns = Contact.column_names + ['labels']
    (column_names.presence || default_columns) & available_columns
  end

  def default_columns
    %w[id name email phone_number labels]
  end
end
