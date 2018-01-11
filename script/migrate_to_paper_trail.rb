PaperTrailVersion.delete_all

versions_query = VestalVersions::Version
    .where(versioned_type: ["DiscountCode", "Event", "SingleDayEvent", "MultidayEvent", "Series", "WeeklySeries"])

count = versions_query.count
index = 0

PaperTrailVersion.transaction do
  puts "Remove old attributes from versions"
  versions_query.find_each do |version|
    index = index + 1
    if index % 1000 == 0
      puts "#{index}/#{count}"
    end

    case version.versioned_type
    when "DiscountCode"
      modifications = version.modifications
      modifications.delete("status")
      modifications.delete("use_for")
      version.update_attributes! modifications: modifications
    when "Event", "SingleDayEvent", "MultidayEvent", "Series", "WeeklySeries"
      modifications = version.modifications
      modifications.delete("notification")
      modifications.delete("lock_version")
      version.update_attributes! modifications: modifications
    end
  end

  puts
  puts "Copy versions to PaperTrail"
  count = VestalVersions::Version.count
  index = 0
  [
    DiscountCode,
    Event,
    Page,
    Person,
    Race,
    RaceNumber,
    Refund,
    Team
  ].each do |record_class|
    puts
    puts record_class
    record_class.find_each do |record|
      index = index + 1
      if index % 1000 == 0
        puts "#{index}/#{count}"
      end
      versions = record.versions
      max_version = versions.size - 1

      (0..max_version).each do |index|
        begin
          version = versions[index]
          record.reload.revert_to index

          attributes = record.attributes.dup
          attributes.delete(:lock_version)
          attributes.delete(:notification)
          attributes.delete(:use_for)

          if record.is_a?(DiscountCode)
            attributes.delete(:status)
          end

          PaperTrailVersion.create!(
            created_at: version.updated_at,
            event: index == 0 ? "create" : "update",
            item_type: version.versioned_type,
            item_id: record.id,
            object: attributes.to_yaml,
            whodunnit: record.updated_by_person_name
          )
        rescue ActiveModel::MissingAttributeError => e
          puts "#{e} for #{record_class} ID #{record.id} version #{index}"
          pp attributes
          raise e
        rescue StandardError => e
          puts "Could not migrate #{record_class} ID #{record.id} version #{index}"
          pp version
          raise e
        end
      end
    end
  end

  rollback!
end
