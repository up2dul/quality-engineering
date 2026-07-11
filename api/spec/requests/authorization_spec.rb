# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Authorization' do
  let(:tenant) { create(:organization) }
  let(:admin_user) { create(:user, role: 'admin') }
  let(:regular_user) { create(:user, role: 'user') }
  let(:admin_token) { build_jwt(user_id: admin_user.id, role: 'admin', scheme: tenant.scheme) }
  let(:user_token) { build_jwt(user_id: regular_user.id, role: 'user', scheme: tenant.scheme) }
  let(:invalid_token) { 'invalid.jwt.token' }

  before do
    set_current_tenant(tenant)
  end

  describe 'Assessments (require :assessor role)' do
    let!(:assessment) { create(:assessment, tenant_id: tenant.id, created_by: admin_user.id) }

    it 'allows admin to access assessments' do
      get '/api/v1/assessments', headers: auth_headers(admin_token)
      expect(response).to have_http_status(:ok)
    end

    it 'blocks regular user from accessing assessments' do
      get '/api/v1/assessments', headers: auth_headers(user_token)
      expect(response).to be_forbidden_or_unauthorized
    end

    it 'blocks unauthenticated requests' do
      get '/api/v1/assessments'
      expect(response).to have_http_status(:unauthorized)
    end

    it 'blocks invalid tokens' do
      get '/api/v1/assessments', headers: auth_headers(invalid_token)
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'Vacancies (require :assessor role)' do
    let!(:vacancy) { create(:vacancy, tenant_id: tenant.id, created_by: admin_user.id) }

    it 'allows admin to access vacancies' do
      get '/api/v1/vacancies', headers: auth_headers(admin_token)
      expect(response).to have_http_status(:ok)
    end

    it 'blocks regular user from accessing vacancies' do
      get '/api/v1/vacancies', headers: auth_headers(user_token)
      expect(response).to be_forbidden_or_unauthorized
    end
  end

  describe 'Sessions (require :assessor role except candidate endpoints)' do
    let!(:assessment) { create(:assessment, tenant_id: tenant.id, created_by: admin_user.id) }
    let!(:session) { create(:session, assessment: assessment, tenant_id: tenant.id) }

    it 'allows admin to list sessions' do
      get "/api/v1/assessments/#{assessment.id}/sessions", headers: auth_headers(admin_token)
      expect(response).to have_http_status(:ok)
    end

    it 'allows admin to view session' do
      get "/api/v1/sessions/#{session.id}", headers: auth_headers(admin_token)
      expect(response).to have_http_status(:ok)
    end

    it 'allows admin to end session' do
      post "/api/v1/sessions/#{session.id}/end_session",
           params: { session: { reason: 'manual_assessor' } }.to_json,
           headers: auth_headers(admin_token)
      expect(response).to have_http_status(:ok)
    end

    it 'blocks regular user from listing sessions' do
      get "/api/v1/assessments/#{assessment.id}/sessions", headers: auth_headers(user_token)
      expect(response).to be_forbidden_or_unauthorized
    end

    describe 'candidate endpoints (no JWT required)' do
      it 'allows access to candidate_info with valid invite token' do
        get "/api/v1/sessions/#{session.invite_token}/candidate"
        expect(response).to have_http_status(:ok)
      end

      it 'rejects invalid invite token' do
        get '/api/v1/sessions/invalid-token/candidate'
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'Portfolios (require :assessor role)' do
    let!(:assessment) { create(:assessment, tenant_id: tenant.id, created_by: admin_user.id) }
    let!(:session) { create(:session, assessment: assessment, tenant_id: tenant.id) }
    let!(:portfolio) { create(:portfolio, session: session, generation_status: 'complete') }

    it 'allows admin to view portfolio' do
      get "/api/v1/sessions/#{session.id}/portfolio", headers: auth_headers(admin_token)
      expect(response).to have_http_status(:ok)
    end

    it 'blocks regular user from viewing portfolio' do
      get "/api/v1/sessions/#{session.id}/portfolio", headers: auth_headers(user_token)
      expect(response).to be_forbidden_or_unauthorized
    end
  end
end
