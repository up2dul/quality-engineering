# frozen_string_literal: true

module RequestSpecHelper
  def json_response
    JSON.parse(response.body).with_indifferent_access
  end

  def auth_headers(token)
    { 'Authorization' => "Bearer #{token}", 'Content-Type' => 'application/json' }
  end

  def build_jwt(user_id:, role: 'admin', scheme: 'test-tenant')
    payload = { user_id: user_id, role: role, scheme: scheme, exp: 24.hours.from_now.to_i }
    JsonWebToken.encode(payload)
  end

  def create_tenant(name: 'Test Tenant', host: 'test.example.com')
    Organization.create!(
      name: name,
      scheme: "test-#{SecureRandom.hex(4)}",
      identifier: "test-#{SecureRandom.hex(4)}",
      host: host,
      config: {}
    )
  end

  def set_current_tenant(organization)
    Current.organization = organization
    Current.tenant_id = organization.id
    RequestStore.store[:organization] = organization
    RequestStore.store[:tenant_id] = organization.id
  end
end
