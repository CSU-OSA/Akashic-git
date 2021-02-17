# frozen_string_literal: true

module Resolvers
  class ProjectPipelineResolver < BaseResolver
    type ::Types::Ci::PipelineType, null: true

    alias_method :project, :object

    argument :iid, GraphQL::ID_TYPE,
             required: false,
             description: 'IID of the Pipeline, e.g., "1".'

    argument :sha, GraphQL::STRING_TYPE,
             required: false,
             description: 'Sha of the Pipeline, e.g., ""dyd0f15ay83993f5ab66k927w28673882x99100b".'

    def ready?(iid: nil, sha: nil)
      unless iid.present? ^ sha.present?
        raise Gitlab::Graphql::Errors::ArgumentError, 'Provide either an iid or sha'
      end

      super
    end

    def resolve(iid: nil, sha: nil)
      if iid
        BatchLoader::GraphQL.for(iid).batch(key: project) do |iids, loader, args|
          finder = ::Ci::PipelinesFinder.new(project, context[:current_user], iids: iids)

          finder.execute.each { |pipeline| loader.call(pipeline.iid.to_s, pipeline) }
        end
      else
        BatchLoader::GraphQL.for(sha).batch(key: project) do |shas, loader, args|
          finder = ::Ci::PipelinesFinder.new(project, context[:current_user], shas: sha)

          finder.execute.each { |pipeline| loader.call(pipeline.sha.to_s, pipeline) }
        end
      end
    end
  end
end
