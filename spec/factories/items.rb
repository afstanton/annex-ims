FactoryBot.define do
  factory :item do
    sequence(:barcode) { |n| "000012345#{n}" }
    title Faker::Lorem.sentence
    author Faker::Name.name
    chron 'Vol 1'
    thickness 1
    tray nil
    bib_number "0037612#{Faker::Number.number(digits: 2)}"
    isbn_issn [true, false].sample ? Faker::Code.isbn : "#{Faker::Number.number(digits: 4)}-#{Faker::Number.number(digits: 4)}"
    conditions [Item::CONDITIONS.sample, Item::CONDITIONS.sample, Item::CONDITIONS.sample, Item::CONDITIONS.sample].uniq
    call_number "#{('A'..'Z').to_a.sample}#{('A'..'Z').to_a.sample}#{Faker::Number.number(digits: 4)}.#{('A'..'Z').to_a.sample}#{Faker::Number.number(digits: 2)} #{(1900..2014).to_a.sample}"
    initial_ingest Faker::Date.between(from: 2.days.ago, to: Date.today)
    last_ingest Date::today.to_s
    metadata_status 'complete'
    disposition nil
    status 0

    # Note: This should be the last trait in the list so `reindex` is called
    # after all the other callbacks complete.
    trait :reindex do
      after(:create) do |item, _evaluator|
        item.reindex(refresh: true)
      end
    end
  end
end
