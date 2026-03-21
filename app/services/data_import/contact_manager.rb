class DataImport::ContactManager
  def initialize(account)
    @account = account
  end

  def build_contact(params)
    contact = find_or_initialize_contact(params)
    update_contact_attributes(params, contact)
    contact
  end

  def find_or_initialize_contact(params)
    contact = find_existing_contact(params)
    contact_params = params.slice(:email, :identifier, :phone_number)
    contact_params[:phone_number] = format_phone_number(contact_params[:phone_number]) if contact_params[:phone_number].present?
    contact ||= @account.contacts.new(contact_params)
    contact
  end

  def find_existing_contact(params)
    contact = find_contact_by_identifier(params)
    contact ||= find_contact_by_email(params)
    contact ||= find_contact_by_phone_number(params)

    update_contact_with_merged_attributes(params, contact) if contact.present? && contact.valid?
    contact
  end

  def find_contact_by_identifier(params)
    return unless params[:identifier]

    @account.contacts.find_by(identifier: params[:identifier])
  end

  def find_contact_by_email(params)
    return unless params[:email]

    @account.contacts.from_email(params[:email])
  end

  def find_contact_by_phone_number(params)
    return unless params[:phone_number]

    @account.contacts.find_by(phone_number: format_phone_number(params[:phone_number]))
  end

  def format_phone_number(phone_number)
    phone_number.start_with?('+') ? phone_number : "+#{phone_number}"
  end

  def update_contact_with_merged_attributes(params, contact)
    contact.identifier = params[:identifier] if params[:identifier].present?
    contact.email = params[:email] if params[:email].present?
    contact.phone_number = format_phone_number(params[:phone_number]) if params[:phone_number].present?
    update_contact_attributes(params, contact)
    contact.save
  end

  private

  def resolve_country_code(country_name)
    return nil if country_name.blank?

    @country_map ||= begin
      file_path = Rails.root.join('app', 'javascript', 'shared', 'constants', 'countries.js')
      content = File.read(file_path)
      map = {}
      content.scan(/name:\s*'([^']+)'[^}]+id:\s*'([^']+)'/m) do |name, id|
        map[name.strip.downcase] = id.strip
      end
      map
    end

    @country_map[country_name.strip.downcase]
  end

  def update_contact_attributes(params, contact)
    contact.name = params[:name] if params[:name].present?
    
    if params[:labels].present?
      contact.label_list.add(params[:labels].split(',').map(&:strip))
    end
    
    contact.additional_attributes ||= {}
    %w[company_name description city country country_code].each do |attr|
      contact.additional_attributes[attr] = params[attr.to_sym] if params[attr.to_sym].present?
    end

    if contact.additional_attributes['country'].present? && contact.additional_attributes['country_code'].blank?
      resolved_code = resolve_country_code(contact.additional_attributes['country'])
      contact.additional_attributes['country_code'] = resolved_code if resolved_code
    end

    contact.assign_attributes(custom_attributes: contact.custom_attributes.merge(params.except(:identifier, :email, :name, :phone_number, :labels, :company_name, :description, :city, :country, :country_code)))
  end
end
