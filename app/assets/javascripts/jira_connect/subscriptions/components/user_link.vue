<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { __ } from '~/locale';
import { getGitlabSignInURL } from '~/jira_connect/subscriptions/utils';

export default {
  components: {
    GlLink,
    GlSprintf,
    SignInOauthButton: () => import('./sign_in_oauth_button.vue'),
  },
  mixins: [glFeatureFlagMixin()],
  inject: {
    usersPath: {
      default: '',
    },
    gitlabUserPath: {
      default: '',
    },
  },
  props: {
    userSignedIn: {
      type: Boolean,
      required: true,
    },
    hasSubscriptions: {
      type: Boolean,
      required: true,
    },
    user: {
      type: Object,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      signInURL: '',
    };
  },
  computed: {
    gitlabUserName() {
      return gon.current_username ?? this.user?.username;
    },
    gitlabUserHandle() {
      return this.gitlabUserName ? `@${this.gitlabUserName}` : undefined;
    },
    gitlabUserLink() {
      return this.gitlabUserPath ?? `${gon.relative_root_url}/${this.gitlabUserName}`;
    },
    signedInText() {
      return this.gitlabUserHandle
        ? this.$options.i18n.signedInAsUserText
        : this.$options.i18n.signedInText;
    },
    isOauthEnabled() {
      return this.glFeatures.jiraConnectOauth;
    },
  },
  async created() {
    this.signInURL = await getGitlabSignInURL(this.usersPath);
  },
  i18n: {
    signInText: __('Sign in to GitLab'),
    signedInAsUserText: __('Signed in to GitLab as %{user_link}'),
    signedInText: __('Signed in to GitLab'),
  },
};
</script>
<template>
  <div class="gl-font-base">
    <gl-sprintf v-if="userSignedIn" :message="signedInText">
      <template #user_link>
        <gl-link data-testid="gitlab-user-link" :href="gitlabUserLink" target="_blank">
          {{ gitlabUserHandle }}
        </gl-link>
      </template>
    </gl-sprintf>

    <template v-else-if="hasSubscriptions">
      <sign-in-oauth-button v-if="isOauthEnabled" category="tertiary">
        {{ $options.i18n.signInText }}
      </sign-in-oauth-button>

      <gl-link v-else data-testid="sign-in-link" :href="signInURL" target="_blank">
        {{ $options.i18n.signInText }}
      </gl-link>
    </template>
  </div>
</template>
