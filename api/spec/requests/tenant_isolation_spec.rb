# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Tenant Isolation' do
  let(:tenant_a) { create(:organization, name: 'Tenant A') }
  let(:tenant_b) { create(:organization, name: 'Tenant B') }
  let(:user_a) { create(:user) }
  let(:user_b) { create(:user) }
  let(:token_a) { build_jwt(user_id: user_a.id, role: 'admin', scheme: tenant_a.scheme) }
  let(:token_b) { build_jwt(user_id: user_b.id, role: 'admin', scheme: tenant_b.scheme) }

  describe 'Assessments' do
    let!(:assessment_a) { create(:assessment, tenant_id: tenant_a.id, created_by: user_a.id, name: 'Assessment A') }
    let!(:assessment_b) { create(:assessment, tenant_id: tenant_b.id, created_by: user_b.id, name: 'Assessment B') }

    it 'tenant A cannot see tenant B assessments' do
      get '/api/v1/assessments', headers: auth_headers(token_a)

      expect(response).to have_http_status(:ok)
      assessment_ids = json_response[:assessments].map { |a| a['id'] }
      expect(assessment_ids).to include(assessment_a.id)
      expect(assessment_ids).not_to include(assessment_b.id)
    end

    it 'tenant A cannot access tenant B assessment by ID' do
      get "/api/v1/assessments/#{assessment_b.id}", headers: auth_headers(token_a)

      expect(response).to have_http_status(:not_found)
    end

    it 'tenant A cannot update tenant B assessment' do
      put "/api/v1/assessments/#{assessment_b.id}",
          params: { assessment: { name: 'Hacked' } }.to_json,
          headers: auth_headers(token_a)

      expect(response).to have_http_status(:not_found)
    end

    it 'tenant A cannot delete tenant B assessment' do
      delete "/api/v1/assessments/#{assessment_b.id}", headers: auth_headers(token_a)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'Sessions' do
    let!(:assessment_a) { create(:assessment, tenant_id: tenant_a.id, created_by: user_a.id) }
    let!(:assessment_b) { create(:assessment, tenant_id: tenant_b.id, created_by: user_b.id) }
    let!(:session_a) { create(:session, assessment: assessment_a, tenant_id: tenant_a.id) }
    let!(:session_b) { create(:session, assessment: assessment_b, tenant_id: tenant_b.id) }

    it 'tenant A cannot see tenant B sessions' do
      get "/api/v1/assessments/#{assessment_a.id}/sessions", headers: auth_headers(token_a)

      expect(response).to have_http_status(:ok)
      session_ids = json_response[:sessions].map { |s| s['id'] }
      expect(session_ids).to include(session_a.id)
      expect(session_ids).not_to include(session_b.id)
    end

    it 'tenant A cannot access tenant B session by ID' do
      get "/api/v1/sessions/#{session_b.id}", headers: auth_headers(token_a)

      expect(response).to have_http_status(:not_found)
    end

    it 'tenant A cannot end tenant B session' do
      post "/api/v1/sessions/#{session_b.id}/end_session",
           params: { session: { reason: 'manual_assessor' } }.to_json,
           headers: auth_headers(token_a)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'Vacancies' do
    let!(:vacancy_a) { create(:vacancy, tenant_id: tenant_a.id, created_by: user_a.id, role_title: 'Vacancy A') }
    let!(:vacancy_b) { create(:vacancy, tenant_id: tenant_b.id, created_by: user_b.id, role_title: 'Vacancy B') }

    it 'tenant A cannot see tenant B vacancies' do
      get '/api/v1/vacancies', headers: auth_headers(token_a)

      expect(response).to have_http_status(:ok)
      vacancy_ids = json_response[:vacancies].map { |v| v['id'] }
      expect(vacancy_ids).to include(vacancy_a.id)
      expect(vacancy_ids).not_to include(vacancy_b.id)
    end

    it 'tenant A cannot access tenant B vacancy by ID' do
      get "/api/v1/vacancies/#{vacancy_b.id}", headers: auth_headers(token_a)

      expect(response).to have_http_status(:not_found)
    end

    it 'tenant A cannot update tenant B vacancy' do
      put "/api/v1/vacancies/#{vacancy_b.id}",
          params: { vacancy: { role_title: 'Hacked' } }.to_json,
          headers: auth_headers(token_a)

      expect(response).to have_http_status(:not_found)
    end

    it 'tenant A cannot delete tenant B vacancy' do
      delete "/api/v1/vacancies/#{vacancy_b.id}", headers: auth_headers(token_a)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'Portfolios' do
    let!(:assessment_a) { create(:assessment, tenant_id: tenant_a.id, created_by: user_a.id) }
    let!(:assessment_b) { create(:assessment, tenant_id: tenant_b.id, created_by: user_b.id) }
    let!(:session_a) { create(:session, assessment: assessment_a, tenant_id: tenant_a.id) }
    let!(:session_b) { create(:session, assessment: assessment_b, tenant_id: tenant_b.id) }
    let!(:portfolio_a) { create(:portfolio, session: session_a, generation_status: 'complete') }
    let!(:portfolio_b) { create(:portfolio, session: session_b, generation_status: 'complete') }

    it 'tenant A cannot access tenant B portfolio' do
      get "/api/v1/sessions/#{session_b.id}/portfolio", headers: auth_headers(token_a)

      expect(response).to have_http_status(:not_found)
    end

    it 'tenant A cannot export tenant B portfolio' do
      get "/api/v1/portfolios/#{portfolio_b.id}/export", headers: auth_headers(token_a)

      expect(response).to have_http_status(:not_found)
    end
  end
end
