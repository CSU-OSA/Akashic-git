require 'spec_helper'

describe Commits::UpdateService do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  let(:commit) { create(:commit, project: project) }

  before do
    project.add_maintainer(user)
  end

  describe 'execute' do
    let(:service) { described_class.new(project, user, opts) }

    context 'valid params' do
      let(:opts) do
        {
          tag_name: '1.2.3',
          tag_message: 'Release'
        }
      end

      it 'tags a commit' do
        tag_stub = instance_double(Tags::CreateService)
        allow(Tags::CreateService).to receive(:new).and_return(tag_stub)
        allow(tag_stub).to receive(:execute)
          .with(opts[:tag_name], commit.sha, opts[:tag_message], nil)
          .and_return({ status: :success })

        service.execute(commit)
      end
    end

    context 'invalid params' do
      let(:opts) do
        {}
      end

      it 'does not call the tag create service' do
        expect(Tags::CreateService).not_to receive(:new)

        service.execute(commit)
      end
    end
  end
end
