# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::EE::API::Entities::UserWithAdmin do
  subject { entity.as_json }

  let_it_be(:user) { create(:user) }
  let(:entity) { ::API::Entities::UserWithAdmin.new(user) }

  context 'using_license_seat' do
    context 'when user is using seat' do
      it 'returns true' do
        expect(subject[:using_license_seat]).to be true
      end
    end

    context 'when user is not using seat' do
      it 'returns false' do
        allow(user).to receive(:using_license_seat?).and_return(false)

        expect(subject[:using_license_seat]).to be false
      end
    end
  end

  context 'is_auditor' do
    it 'returns false when user is not an auditor' do
      expect(subject[:is_auditor]).to be false
    end

    context 'when user is an auditor' do
      let(:user) { create(:user, :auditor) }

      it 'returns true' do
        expect(subject[:is_auditor]).to be true
      end
    end
  end
end
