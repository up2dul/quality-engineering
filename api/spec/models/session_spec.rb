# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Session do
  describe '#invite_url' do
    let(:tenant) { create(:organization) }
    let(:user) { create(:user) }
    let(:assessment) { create(:assessment, tenant: tenant, created_by: user) }
    let(:session) { create(:session, assessment: assessment, tenant_id: tenant.id) }

    context 'when FRONTEND_URL is set' do
      before do
        allow(ENV).to receive(:fetch).with('FRONTEND_URL', 'http://localhost:5173').and_return('http://localhost:5173')
      end

      it 'returns the frontend URL with the invite token' do
        expect(session.invite_url).to eq("http://localhost:5173/interview/#{session.invite_token}")
      end

      it 'does not point to the API backend' do
        expect(session.invite_url).not_to include(':3001')
      end
    end

    context 'when FRONTEND_URL is not set' do
      before do
        allow(ENV).to receive(:fetch).with('FRONTEND_URL', 'http://localhost:5173').and_return('http://localhost:5173')
      end

      it 'defaults to localhost:5173' do
        expect(session.invite_url).to include('localhost:5173')
      end
    end

    context 'when FRONTEND_URL is set to a custom domain' do
      before do
        allow(ENV).to receive(:fetch).with('FRONTEND_URL', 'http://localhost:5173').and_return('https://interview.example.com')
      end

      it 'uses the custom domain' do
        expect(session.invite_url).to eq("https://interview.example.com/interview/#{session.invite_token}")
      end
    end
  end
end
