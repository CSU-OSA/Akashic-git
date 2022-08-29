# frozen_string_literal: true

require "spec_helper"

RSpec.describe 'Group wikis', :js do
  include WikiHelpers

  let_it_be(:user) { create(:user) }

  let(:group) { create(:group) }
  let(:wiki) { create(:group_wiki, user: user, group: group) }

  before do
    stub_group_wikis(true)
    stub_feature_flags(gl_listbox_for_sort_dropdowns: false)
    wiki.container.add_owner(user)
  end

  context 'with legacy wiki rpcs' do
    before do
      stub_feature_flags(wiki_list_pages_with_normal_repository_rpcs: false)
    end

    it_behaves_like 'User creates wiki page'
    it_behaves_like 'User deletes wiki page'
    it_behaves_like 'User previews wiki changes'
    it_behaves_like 'User updates wiki page'
    it_behaves_like 'User uses wiki shortcuts'
    it_behaves_like 'User views AsciiDoc page with includes'
    it_behaves_like 'User views a wiki page'
    it_behaves_like 'User views wiki pages'
    it_behaves_like 'User views wiki sidebar'
    it_behaves_like 'User views Git access wiki page'
  end

  context 'with normal repository rpcs' do
    before do
      stub_feature_flags(wiki_list_pages_with_normal_repository_rpcs: true)
    end

    it_behaves_like 'User creates wiki page'
    it_behaves_like 'User deletes wiki page'
    it_behaves_like 'User previews wiki changes'
    it_behaves_like 'User updates wiki page'
    it_behaves_like 'User uses wiki shortcuts'
    it_behaves_like 'User views AsciiDoc page with includes'
    it_behaves_like 'User views a wiki page'
    it_behaves_like 'User views wiki pages', false
    it_behaves_like 'User views wiki sidebar'
    it_behaves_like 'User views Git access wiki page'
  end
end
