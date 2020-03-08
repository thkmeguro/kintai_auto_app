FactoryBot.define do
  factory :device do
    sequence(:slack_authed_user_id) { |n| "ZZZ777TT#{n}" }
    sequence(:mac_address) { |n| "aa:bb:cc:dd:ee:1#{n}" }
    device_type { 'machine_mac_address' }
    created_at { Time.zone.now }
    updated_at { Time.zone.now }
    deleted { false }
  end

  trait(:device_deleted) do
    deleted { true }
  end
end
