# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Bitbucket::Representation::User do
  describe '#username' do
    it 'returns correct value' do
      user = described_class.new('username' => 'Ben')

      expect(user.username).to eq('Ben')
    end
  end
end
