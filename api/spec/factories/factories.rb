# frozen_string_literal: true

FactoryBot.define do
  factory :organization do
    sequence(:name) { |n| "Organization #{n}" }
    sequence(:scheme) { |n| "org-#{n}" }
    sequence(:identifier) { |n| "org-#{n}" }
    sequence(:host) { |n| "org-#{n}.example.com" }
    config { {} }
  end

  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password_digest { BCrypt::Password.create('password123') }
    role { 'admin' }
  end

  factory :assessment do
    tenant_id { association(:organization).id }
    created_by { association(:user).id }
    name { 'Test Assessment' }
    time_limit_min { 30 }
    language { 'en' }
  end

  factory :assessment_skill do
    association :assessment
    skill_id { "skill-#{SecureRandom.hex(4)}" }
    skill_label { 'Test Skill' }
    l1_anchor { 'L1' }
    l2_anchor { 'L2' }
    l3_anchor { 'L3' }
    l4_anchor { 'L4' }
    l5_anchor { 'L5' }
    expected_level { 3 }
  end

  factory :session do
    association :assessment
    tenant_id { assessment.tenant_id }
    status { 'pending' }
    candidate_name { 'Test Candidate' }
  end

  factory :vacancy do
    tenant_id { association(:organization).id }
    created_by { association(:user).id }
    role_title { 'Software Engineer' }
  end

  factory :vacancy_skill do
    association :vacancy
    skill_id { "skill-#{SecureRandom.hex(4)}" }
    skill_label { 'Test Skill' }
    expected_level { 3 }
  end

  factory :portfolio do
    association :session
    generation_status { 'pending' }
  end

  factory :portfolio_skill do
    association :portfolio
    skill_id { "skill-#{SecureRandom.hex(4)}" }
    skill_label { 'Test Skill' }
    ai_level { 3 }
    ai_confidence { 'medium' }
    competency_summary { 'Test summary' }
  end

  factory :coverage_map do
    association :session
    skill_id { "skill-#{SecureRandom.hex(4)}" }
    skill_label { 'Test Skill' }
    state { 'not_yet' }
  end

  factory :transcript_turn do
    association :session
    turn_number { 1 }
    speaker { 'ai' }
    text { 'Hello, how are you?' }
  end
end
