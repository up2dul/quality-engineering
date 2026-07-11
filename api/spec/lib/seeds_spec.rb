# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'User seeding' do
  before do
    # Clean up any existing users
    User.delete_all
  end

  it 'creates admin and regular users when seeding' do
    # Run the seed file
    load Rails.root.join('db/seeds.rb')

    # Verify users were created
    admin = User.find_by(email: 'admin@test.com')
    regular_user = User.find_by(email: 'user@test.com')

    expect(admin).to be_present
    expect(admin.role).to eq('admin')
    expect(admin.authenticate('password123')).to be_truthy

    expect(regular_user).to be_present
    expect(regular_user.role).to eq('user')
    expect(regular_user.authenticate('password123')).to be_truthy
  end

  it 'does not duplicate users when seeding multiple times' do
    # Run the seed file twice
    load Rails.root.join('db/seeds.rb')
    load Rails.root.join('db/seeds.rb')

    # Verify only one of each user exists
    expect(User.where(email: 'admin@test.com').count).to eq(1)
    expect(User.where(email: 'user@test.com').count).to eq(1)
  end
end
