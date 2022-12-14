import $ from 'jquery';
import { sprintf, __ } from '~/locale';
import { sanitizeUrl } from '~/lib/utils/url_utility';
import AccessorUtilities from './lib/utils/accessor';
import { loadCSSFile } from './lib/utils/css_utils';

export default class ProjectSelectComboButton {
  constructor(select) {
    this.projectSelectInput = $(select);
    this.newItemBtn = $('.js-new-project-item-link');
    this.resourceType = this.newItemBtn.data('type');
    this.resourceLabel = this.newItemBtn.data('label');
    this.formattedText = this.deriveTextVariants();
    this.groupId = this.projectSelectInput.data('groupId');
    this.bindEvents();
    this.initLocalStorage();
  }

  bindEvents() {
    this.projectSelectInput
      .siblings('.new-project-item-select-button')
      .on('click', (e) => this.openDropdown(e));

    this.newItemBtn.on('click', (e) => {
      if (!this.getProjectFromLocalStorage()) {
        e.preventDefault();
        this.openDropdown(e);
      }
    });

    this.projectSelectInput.on('change', () => this.selectProject());
  }

  initLocalStorage() {
    const localStorageIsSafe = AccessorUtilities.canUseLocalStorage();

    if (localStorageIsSafe) {
      this.localStorageKey = [
        'group',
        this.groupId,
        this.formattedText.localStorageItemType,
        'recent-project',
      ].join('-');
      this.setBtnTextFromLocalStorage();
    }
  }

  // eslint-disable-next-line class-methods-use-this
  openDropdown(event) {
    import(/* webpackChunkName: 'select2' */ 'select2/select2')
      .then(() => {
        // eslint-disable-next-line promise/no-nesting
        loadCSSFile(gon.select2_css_path)
          .then(() => {
            $(event.currentTarget).siblings('.project-item-select').select2('open');
          })
          .catch(() => {});
      })
      .catch(() => {});
  }

  selectProject() {
    const selectedProjectData = JSON.parse(this.projectSelectInput.val());
    const projectUrl = `${selectedProjectData.url}/${this.projectSelectInput.data('relativePath')}`;
    const projectName = selectedProjectData.name;

    const projectMeta = {
      url: projectUrl,
      name: projectName,
    };

    this.setNewItemBtnAttributes(projectMeta);
    this.setProjectInLocalStorage(projectMeta);
  }

  setBtnTextFromLocalStorage() {
    const cachedProjectData = this.getProjectFromLocalStorage();

    this.setNewItemBtnAttributes(cachedProjectData);
  }

  setNewItemBtnAttributes(project) {
    if (project) {
      this.newItemBtn.attr('href', sanitizeUrl(project.url));
      this.newItemBtn.text(
        sprintf(__('New %{type} in %{project}'), {
          type: this.resourceLabel,
          project: project.name,
        }),
      );
    } else {
      this.newItemBtn.text(
        sprintf(__('Select project to create %{type}'), {
          type: this.formattedText.presetTextSuffix,
        }),
      );
    }
  }

  getProjectFromLocalStorage() {
    const projectString = localStorage.getItem(this.localStorageKey);

    return JSON.parse(projectString);
  }

  setProjectInLocalStorage(projectMeta) {
    const projectString = JSON.stringify(projectMeta);

    localStorage.setItem(this.localStorageKey, projectString);
  }

  deriveTextVariants() {
    // the trailing slice call depluralizes each of these strings (e.g. new-issues -> new-issue)
    const localStorageItemType = `new-${this.resourceType.split('_').join('-').slice(0, -1)}`;
    const presetTextSuffix = this.resourceType.split('_').join(' ').slice(0, -1);

    return {
      localStorageItemType, // new-issue / new-merge-request
      presetTextSuffix, // issue / merge request
    };
  }
}
