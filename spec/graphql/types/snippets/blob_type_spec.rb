# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['SnippetBlob'] do
  include GraphqlHelpers

  it 'has the correct fields' do
    expected_fields = [:rich_data, :plain_data,
                       :raw_path, :size, :binary, :name, :path,
                       :simple_viewer, :rich_viewer, :mode, :external_storage,
                       :rendered_as_text]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  specify { expect(described_class.fields['richData'].type).not_to be_non_null }
  specify { expect(described_class.fields['plainData'].type).not_to be_non_null }
  specify { expect(described_class.fields['rawPath'].type).to be_non_null }
  specify { expect(described_class.fields['size'].type).to be_non_null }
  specify { expect(described_class.fields['binary'].type).to be_non_null }
  specify { expect(described_class.fields['name'].type).not_to be_non_null }
  specify { expect(described_class.fields['path'].type).not_to be_non_null }
  specify { expect(described_class.fields['simpleViewer'].type).to be_non_null }
  specify { expect(described_class.fields['richViewer'].type).not_to be_non_null }
  specify { expect(described_class.fields['mode'].type).not_to be_non_null }
  specify { expect(described_class.fields['externalStorage'].type).not_to be_non_null }
  specify { expect(described_class.fields['renderedAsText'].type).to be_non_null }

  let_it_be(:snippet) { create(:snippet, :public, :repository) }

  described_class.fields.each_value do |field|
    it "resolves #{field.graphql_name} using the presenter", :request_store do
      blob = Snippet.find(snippet.id).blobs.first
      presented = SnippetBlobPresenter.new(blob)

      expect(resolve_field(field, blob)).to eq(presented.try(field.method_sym))
    end
  end
end
