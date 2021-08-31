# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Push over HTTP using Git protocol version 2', :requires_git_protocol_v2 do
      it 'user pushes to the repository', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/1548' do
        Flow::Login.sign_in

        # Create a project to push to
        project = Resource::Project.fabricate_via_api! do |project|
          project.name = 'git-protocol-project'
        end

        file_name = 'README.md'
        file_content = 'Test Git protocol v2'
        git_protocol = '2'
        git_protocol_reported = nil

        # Use Git to clone the project, push a file to it, and then check the
        # supported Git protocol
        Git::Repository.perform do |repository|
          username = 'GitLab QA'
          email = 'root@gitlab.com'

          repository.uri = project.repository_http_location.uri
          repository.use_default_credentials
          repository.clone
          repository.configure_identity(username, email)
          repository.default_branch = project.default_branch
          repository.checkout(project.default_branch, new_branch: true)

          git_protocol_reported = repository.push_with_git_protocol(
            git_protocol,
            file_name,
            file_content)
        end

        project.visit!
        project.wait_for_push_new_branch

        # Check that the push worked
        Page::Project::Show.perform do |project_page|
          expect(project_page).to have_file(file_name)
          expect(project_page).to have_readme_content(file_content)
        end

        # And check that the correct Git protocol was used
        expect(git_protocol_reported).to eq(git_protocol)
      end
    end
  end
end
