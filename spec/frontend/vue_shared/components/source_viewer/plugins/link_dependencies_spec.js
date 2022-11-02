import packageJsonLinker from '~/vue_shared/components/source_viewer/plugins/utils/package_json_linker';
import godepsJsonLinker from '~/vue_shared/components/source_viewer/plugins/utils/godeps_json_linker';
import gemspecLinker from '~/vue_shared/components/source_viewer/plugins/utils/gemspec_linker';
import linkDependencies from '~/vue_shared/components/source_viewer/plugins/link_dependencies';
import {
  PACKAGE_JSON_FILE_TYPE,
  PACKAGE_JSON_CONTENT,
  GEMSPEC_FILE_TYPE,
  GODEPS_JSON_FILE_TYPE,
} from './mock_data';

jest.mock('~/vue_shared/components/source_viewer/plugins/utils/package_json_linker');
jest.mock('~/vue_shared/components/source_viewer/plugins/utils/gemspec_linker');
jest.mock('~/vue_shared/components/source_viewer/plugins/utils/godeps_json_linker');

describe('Highlight.js plugin for linking dependencies', () => {
  const hljsResultMock = { value: 'test' };

  it('calls packageJsonLinker for package_json file types', () => {
    linkDependencies(hljsResultMock, PACKAGE_JSON_FILE_TYPE, PACKAGE_JSON_CONTENT);
    expect(packageJsonLinker).toHaveBeenCalled();
  });

  it('calls gemspecLinker for gemspec file types', () => {
    linkDependencies(hljsResultMock, GEMSPEC_FILE_TYPE);
    expect(gemspecLinker).toHaveBeenCalled();
  });

  it('calls godepsJsonLinker for godeps_json file types', () => {
    linkDependencies(hljsResultMock, GODEPS_JSON_FILE_TYPE);
    expect(godepsJsonLinker).toHaveBeenCalled();
  });
});
