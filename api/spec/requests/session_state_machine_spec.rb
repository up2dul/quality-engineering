# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Session State Machine' do
  let(:tenant) { create(:organization) }
  let(:user) { create(:user, role: 'admin') }
  let(:token) { build_jwt(user_id: user.id, role: 'admin', scheme: tenant.scheme) }
  let(:assessment) { create(:assessment, tenant_id: tenant.id, created_by: user.id) }

  before do
    set_current_tenant(tenant)
  end

  describe 'POST /api/v1/assessments/:assessment_id/sessions' do
    it 'creates a session with pending status' do
      post "/api/v1/assessments/#{assessment.id}/sessions",
           params: { session: { candidate_name: 'Test Candidate' } }.to_json,
           headers: auth_headers(token)

      expect(response).to have_http_status(:created)
      expect(json_response[:session][:status]).to eq('pending')
    end
  end

  describe 'POST /api/v1/sessions/:id/end' do
    context 'when session is pending' do
      let!(:session) { create(:session, assessment: assessment, tenant_id: tenant.id, status: 'pending') }

      it 'can end a pending session' do
        post "/api/v1/sessions/#{session.id}/end_session",
             params: { session: { reason: 'manual_assessor' } }.to_json,
             headers: auth_headers(token)

        expect(response).to have_http_status(:ok)
        expect(session.reload.status).to eq('ended')
      end
    end

    context 'when session is active' do
      let!(:session) { create(:session, assessment: assessment, tenant_id: tenant.id, status: 'active', started_at: Time.current) }

      it 'can end an active session' do
        post "/api/v1/sessions/#{session.id}/end_session",
             params: { session: { reason: 'manual_assessor' } }.to_json,
             headers: auth_headers(token)

        expect(response).to have_http_status(:ok)
        expect(session.reload.status).to eq('ended')
      end
    end

    context 'when session is already ended' do
      let!(:session) { create(:session, assessment: assessment, tenant_id: tenant.id, status: 'ended', ended_at: Time.current) }

      it 'cannot end an already ended session' do
        post "/api/v1/sessions/#{session.id}/end_session",
             params: { session: { reason: 'manual_assessor' } }.to_json,
             headers: auth_headers(token)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response[:errors][0][:message]).to include('already ended')
      end
    end

    context 'when session is failed' do
      let!(:session) { create(:session, assessment: assessment, tenant_id: tenant.id, status: 'failed') }

      it 'can end a failed session' do
        post "/api/v1/sessions/#{session.id}/end_session",
             params: { session: { reason: 'error' } }.to_json,
             headers: auth_headers(token)

        expect(response).to have_http_status(:ok)
        expect(session.reload.status).to eq('ended')
      end
    end

    context 'with invalid end reason' do
      let!(:session) { create(:session, assessment: assessment, tenant_id: tenant.id, status: 'active') }

      it 'rejects invalid end reason' do
        post "/api/v1/sessions/#{session.id}/end_session",
             params: { session: { reason: 'invalid_reason' } }.to_json,
             headers: auth_headers(token)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response[:errors][0][:message]).to include('Invalid end reason')
      end
    end
  end

  describe 'POST /api/v1/sessions/:token/audio_complete' do
    let!(:session) { create(:session, assessment: assessment, tenant_id: tenant.id, status: 'active') }

    it 'ends session when all coverage is complete' do
      post "/api/v1/sessions/#{session.invite_token}/audio_complete"

      expect(response).to have_http_status(:ok)
      expect(json_response[:ended]).to be true
    end

    it 'is idempotent for already ended sessions' do
      session.update!(status: 'ended', ended_at: Time.current)

      post "/api/v1/sessions/#{session.invite_token}/audio_complete"

      expect(response).to have_http_status(:ok)
      expect(json_response[:ended]).to be true
    end

    it 'rejects invalid invite token' do
      post '/api/v1/sessions/invalid-token/audio_complete'

      expect(response).to have_http_status(:not_found)
    end
  end
end
