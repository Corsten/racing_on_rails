PaperTrailVersion.delete_all

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

  record_class.find_each do |record|
    versions = record.versions
    max_version = versions.size - 1

    (0..max_version).each do |index|
      begin
        version = versions[index]
        record.reload.revert_to index

        PaperTrailVersion.create!(
          created_at: version.updated_at,
          event: index == 0 ? "create" : "update",
          item_type: version.versioned_type,
          item_id: record.id,
          object: record.attributes.to_yaml,
          whodunnit: record.updated_by_person_name
        )
      rescue ActiveModel::MissingAttributeError => e
        puts "#{e} for #{record_class} ID #{record.id} version #{index}"
      rescue StandardError => e
        puts "Could not migrate #{record_class} ID #{record.id} version #{index}"
        pp version
        raise e
      end
    end
  end
end
