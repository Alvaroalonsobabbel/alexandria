FactoryBot.define do
  factory :access_token do
    token_digest { nil }
    user 
    api_key 
    accessed_at { '2023-08-14 08:35:57' }
  end
end
