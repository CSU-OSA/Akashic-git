# frozen_string_literal: true

module Types
  module Boards
    class EpicBoardType < BaseObject
      graphql_name 'EpicBoard'
      description 'Represents an epic board'

      accepts ::Boards::EpicBoard
      authorize :read_epic_board

      field :id, type: ::Types::GlobalIDType[::Boards::EpicBoard], null: false,
            description: 'Global ID of the board.'

      field :name, type: GraphQL::STRING_TYPE, null: true,
            description: 'Name of the board.'

      field :hide_backlog_list, type: GraphQL::BOOLEAN_TYPE, null: true,
            description: 'Whether or not backlog list is hidden.'

      field :hide_closed_list, type: GraphQL::BOOLEAN_TYPE, null: true,
            description: 'Whether or not closed list is hidden.'


      field :lists,
            Types::Boards::EpicListType.connection_type,
            null: true,
            description: 'Epic board lists.',
            extras: [:lookahead],
            resolver: Resolvers::Boards::EpicListsResolver
    end
  end
end
