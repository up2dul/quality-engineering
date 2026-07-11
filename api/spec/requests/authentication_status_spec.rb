# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Authentication status codes' do
  let(:tenant) { create(:organization) }
  let(:user) { create(:user, role: 'admin') }

  before do
    set_current_tenant(tenant)
  end

  describe 'requests without authentication token' do
    it 'returns 401 Unauthorized for protected endpoints' do
      get '/api/v1/assessments'
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 401 Unauthorized with appropriate error message' do
      get '/api/v1/assessments'
      expect(json_response[:errors]).to be_present
      expect(json_response[:errors].first[:status]).to eq(401)
    end
  end

  describe 'requests with invalid authentication token' do
    it 'returns 401 Unauthorized for invalid token' do
      get '/api/v1/assessments', headers: { 'Authorization' => 'Bearer invalid.token.here' }
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 401 Unauthorized with appropriate error message' do
      get '/api/v1/assessments', headers: { 'Authorization' => 'Bearer invalid.token.here' }
      expect(json_response[:errors]).to be_present
      expect(json_response[:errors].first[:status]).to eq(401)
    end
  end

  describe 'requests with valid token but wrong role' do
    let(:regular_user) { create(:user, role: 'user') }
    let(:user_token) { build_jwt(user_id: regular_user.id, role: 'user', scheme: tenant.scheme) }

    it 'returns 403 Forbidden for insufficient permissions' do
      get '/api/v1/assessments', headers: auth_headers(user_token)
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 403 Forbidden with appropriate error message' do
      get '/api/v1/assessments', headers: auth_headers(user_token)
      expect(json_response[:errors]).to be_present
      expect(json_response[:errors].first[:status]).to eq(403)
    end
  end

  describe 'requests with valid token and correct role' do
    let(:admin_token) { build_jwt(user_id: user.id, role: 'admin', scheme: tenant.scheme) }

    it 'returns 200 OK for authorized requests' do
      get '/api/v1/assessments', headers: auth_headers(admin_token)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'candidate endpoints (no JWT required)' do
    let!(:assessment) { create(:assessment, tenant_id: tenant.id, created_by: user) }
    let!(:session) { create(:session, assessment: assessment, tenant_id: tenant.id) }

    it 'allows access to candidate_info with valid invite token' do
      get "/api/v1/sessions/#{session.invite_token}/candidate"
      expect(response).to have_http_status(:ok)
    end

    it 'returns 404 for invalid invite token' do
      get '/api/v1/sessions/invalid-token/candidate'
      expect(response).to have_http_status(:not_found)
    end
  end
end
