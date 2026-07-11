# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Portfolio endpoint status codes' do
  let(:tenant) { create(:organization) }
  let(:user) { create(:user, role: 'admin') }
  let(:token) { build_jwt(user_id: user.id, role: 'admin', scheme: tenant.scheme) }
  let(:assessment) { create(:assessment, tenant_id: tenant.id, created_by: user) }
  let(:session) { create(:session, assessment: assessment, tenant_id: tenant.id) }

  before do
    set_current_tenant(tenant)
  end

  describe 'GET /api/v1/sessions/:id/portfolio' do
    context 'when portfolio status is pending' do
      let!(:portfolio) { create(:portfolio, session: session, generation_status: 'pending') }

      it 'returns 202 Accepted' do
        get "/api/v1/sessions/#{session.id}/portfolio", headers: auth_headers(token)
        expect(response).to have_http_status(:accepted)
      end
    end

    context 'when portfolio status is generating' do
      let!(:portfolio) { create(:portfolio, session: session, generation_status: 'generating') }

      it 'returns 202 Accepted' do
        get "/api/v1/sessions/#{session.id}/portfolio", headers: auth_headers(token)
        expect(response).to have_http_status(:accepted)
      end
    end

    context 'when portfolio status is complete' do
      let!(:portfolio) { create(:portfolio, session: session, generation_status: 'complete') }

      it 'returns 200 OK with portfolio data' do
        get "/api/v1/sessions/#{session.id}/portfolio", headers: auth_headers(token)
        expect(response).to have_http_status(:ok)
        expect(json_response[:portfolio]).to be_present
      end
    end

    context 'when portfolio status is failed' do
      let!(:portfolio) do
        create(:portfolio,
               session: session,
               generation_status: 'failed',
               generation_error: 'Gemini API rate limit exceeded')
      end

      it 'returns 503 Service Unavailable with error details' do
        get "/api/v1/sessions/#{session.id}/portfolio", headers: auth_headers(token)
        expect(response).to have_http_status(:service_unavailable)
        expect(json_response[:error]).to eq('Gemini API rate limit exceeded')
        expect(json_response[:portfolio]).to be_present
      end
    end

    context 'when portfolio does not exist' do
      it 'returns 202 Accepted with generating status' do
        get "/api/v1/sessions/#{session.id}/portfolio", headers: auth_headers(token)
        expect(response).to have_http_status(:accepted)
        expect(json_response[:status]).to eq('generating')
      end
    end
  end
end
