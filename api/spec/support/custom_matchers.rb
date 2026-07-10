# frozen_string_literal: true

RSpec::Matchers.define :be_forbidden_or_unauthorized do
  match do |response|
    [401, 403].include?(response.status)
  end

  failure_message do |response|
    "expected response to be 401 or 403, but was #{response.status}"
  end
end
