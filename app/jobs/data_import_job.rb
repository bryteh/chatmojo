# TODO: logic is written tailored to contact import since its the only import available
# let's break this logic and clean this up in future

class DataImportJob < ApplicationJob
  queue_as :low
  retry_on ActiveStorage::FileNotFoundError, wait: 1.minute, attempts: 3

  def perform(data_import)
    @data_import = data_import
    @contact_manager = DataImport::ContactManager.new(@data_import.account)
    begin
      process_import_file
      send_import_notification_to_admin
    rescue CSV::MalformedCSVError => e
      handle_csv_error(e)
    end
  end

  private

  def process_import_file
    @data_import.update!(status: :processing)
    contacts, rejected_contacts = parse_csv_and_build_contacts

    import_contacts(contacts)
    update_data_import_status(contacts.length, rejected_contacts.length)
    save_failed_records_csv(rejected_contacts)
  end

  def parse_csv_and_build_contacts
    contacts = []
    rejected_contacts = []

    with_import_file do |file|
      csv_reader(file).each do |row|
        current_contact = @contact_manager.build_contact(row.to_h.with_indifferent_access)
        if current_contact.valid?
          contacts << current_contact
        else
          append_rejected_contact(row, current_contact, rejected_contacts)
        end
      end
    end

    [contacts, rejected_contacts]
  end

  def append_rejected_contact(row, contact, rejected_contacts)
    row['errors'] = contact.errors.full_messages.join(', ')
    rejected_contacts << row
  end

  def import_contacts(contacts)
    # Cache the parsed labels before they are wiped by the database synchronization mapping natively!
    parsed_labels_cache = contacts.each_with_object({}) do |c, hash|
      key = c.email.presence || c.phone_number.presence
      hash[key] = c.label_list if key.present? && c.label_list.present?
    end

    Contact.import(contacts, synchronize: contacts, on_duplicate_key_ignore: true, track_validation_failures: true, validate: true, batch_size: 1000)
    
    # Pre-emptively register any brand new tag strings into Chatwoot's physical Label database so the UI recognizes them
    unique_labels = parsed_labels_cache.values.flatten.uniq.reject(&:blank?)
    unique_labels.each do |label_name|
      begin
        @data_import.account.labels.find_or_create_by!(title: label_name) do |label|
          label.description = 'Added via CSV import'
          label.show_on_sidebar = true
        end
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error "Failed to pre-create physical label record #{label_name}: #{e.message}"
      end
    end
    
    # Safely assign tags from our isolated memory cache now that instances exist physically
    parsed_labels_cache.each do |lookup_key, tags|
      db_contact = @data_import.account.contacts.find_by(email: lookup_key) || @data_import.account.contacts.find_by(phone_number: lookup_key)
      if db_contact
        db_contact.add_labels(tags)
      end
    end
  end

  def update_data_import_status(processed_records, rejected_records)
    @data_import.update!(status: :completed, processed_records: processed_records, total_records: processed_records + rejected_records)
  end

  def save_failed_records_csv(rejected_contacts)
    csv_data = generate_csv_data(rejected_contacts)
    return if csv_data.blank?

    @data_import.failed_records.attach(io: StringIO.new(csv_data), filename: "#{Time.zone.today.strftime('%Y%m%d')}_contacts.csv",
                                       content_type: 'text/csv')
  end

  def generate_csv_data(rejected_contacts)
    headers = csv_headers
    headers << 'errors'
    return if rejected_contacts.blank?

    CSV.generate do |csv|
      csv << headers
      rejected_contacts.each do |record|
        csv << record
      end
    end
  end

  def handle_csv_error(error) # rubocop:disable Lint/UnusedMethodArgument
    @data_import.update!(status: :failed)
    send_import_failed_notification_to_admin
  end

  def send_import_notification_to_admin
    AdministratorNotifications::AccountNotificationMailer.with(account: @data_import.account).contact_import_complete(@data_import).deliver_later
  end

  def send_import_failed_notification_to_admin
    AdministratorNotifications::AccountNotificationMailer.with(account: @data_import.account).contact_import_failed.deliver_later
  end

  def csv_headers
    header_row = nil
    with_import_file do |file|
      header_row = csv_reader(file).first
    end
    header_row&.headers || []
  end

  def csv_reader(file)
    file.rewind
    raw_data = file.read
    utf8_data = raw_data.force_encoding('UTF-8')
    clean_data = utf8_data.valid_encoding? ? utf8_data : utf8_data.encode('UTF-16le', invalid: :replace, replace: '').encode('UTF-8')

    CSV.new(StringIO.new(clean_data), headers: true)
  end

  def with_import_file
    temp_dir = Rails.root.join('tmp/imports')
    FileUtils.mkdir_p(temp_dir)

    @data_import.import_file.open(tmpdir: temp_dir) do |file|
      file.binmode
      yield file
    end
  end
end
