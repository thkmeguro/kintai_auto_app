FactoryBot.define do
  factory :member do
    sequence(:slack_legacy_token) { |n| "xoxp-111111111111-222222222222-333333333333-11112222aaaabbbb11112222aaaabbb#{n}"}
    sequence(:slack_authed_user_id) { |n| "ZZZ777TT#{n}" }
    sequence(:slack_authed_user_access_token) { |n| "xoxp-911111111111-222222222222-333333333333-11112222aaaabbbb11112222aaaabbb#{n}"}
    has_connected_today { false }
    created_at { Time.zone.now }
    updated_at { Time.zone.now }
    deleted { false }
  end

  trait(:member_deleted) do
    deleted { true }
  end

  trait(:connected) do
    deleted { 1 }
  end
end
