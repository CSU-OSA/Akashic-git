# frozen_string_literal: true

module API
  class RemoteMirrors < ::API::Base
    include PaginationParams

    feature_category :source_code_management

    before do
      unauthorized! unless can?(current_user, :admin_remote_mirror, user_project)
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc "List the project's remote mirrors" do
        success Entities::RemoteMirror
      end
      params do
        use :pagination
      end
      get ':id/remote_mirrors' do
        present paginate(user_project.remote_mirrors),
          with: Entities::RemoteMirror
      end

      desc 'Get a single remote mirror' do
        success Entities::RemoteMirror
      end
      params do
        requires :mirror_id, type: String, desc: 'The ID of a remote mirror'
      end
      get ':id/remote_mirrors/:mirror_id' do
        mirror = user_project.remote_mirrors.find(params[:mirror_id])

        present mirror, with: Entities::RemoteMirror
      end

      desc 'Create remote mirror for a project' do
        success Entities::RemoteMirror
      end
      params do
        requires :url, type: String, desc: 'The URL for a remote mirror'
        optional :enabled, type: Boolean, desc: 'Determines if the mirror is enabled'
        optional :only_protected_branches, type: Boolean, desc: 'Determines if only protected branches are mirrored'
        optional :keep_divergent_refs, type: Boolean, desc: 'Determines if divergent refs are kept on the target'
      end
      post ':id/remote_mirrors' do
        create_params = declared_params(include_missing: false)

        new_mirror = user_project.remote_mirrors.create(create_params)

        if new_mirror.persisted?
          present new_mirror, with: Entities::RemoteMirror
        else
          render_validation_error!(new_mirror)
        end
      end

      desc 'Update the attributes of a single remote mirror' do
        success Entities::RemoteMirror
      end
      params do
        requires :mirror_id, type: String, desc: 'The ID of a remote mirror'
        optional :enabled, type: Boolean, desc: 'Determines if the mirror is enabled'
        optional :only_protected_branches, type: Boolean, desc: 'Determines if only protected branches are mirrored'
        optional :keep_divergent_refs, type: Boolean, desc: 'Determines if divergent refs are kept on the target'
      end
      put ':id/remote_mirrors/:mirror_id' do
        mirror = user_project.remote_mirrors.find(params[:mirror_id])

        mirror_params = declared_params(include_missing: false)
        mirror_params[:id] = mirror_params.delete(:mirror_id)

        update_params = { remote_mirrors_attributes: mirror_params }

        result = ::Projects::UpdateService
          .new(user_project, current_user, update_params)
          .execute

        if result[:status] == :success
          present mirror.reset, with: Entities::RemoteMirror
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end

      desc 'Delete a single remote mirror' do
        detail 'This feature was introduced in GitLab 14.10'
      end
      params do
        requires :mirror_id, type: String, desc: 'The ID of a remote mirror'
      end
      delete ':id/remote_mirrors/:mirror_id' do
        mirror = user_project.remote_mirrors.find(params[:mirror_id])

        destroy_conditionally!(mirror) do
          mirror_params = declared_params(include_missing: false).merge(_destroy: 1)
          mirror_params[:id] = mirror_params.delete(:mirror_id)
          update_params = { remote_mirrors_attributes: mirror_params }

          # Note: We are using the update service to be consistent with how the controller handles deletion
          result = ::Projects::UpdateService.new(user_project, current_user, update_params).execute

          if result[:status] != :success
            render_api_error!(result[:message], 400)
          end
        end
      end
    end
  end
end
