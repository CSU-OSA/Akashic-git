<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
  },
  props: {
    commits: {
      type: Array,
      required: true,
      default: () => [],
    },
  },
};
</script>

<template>
  <div>
    <gl-dropdown
      right
      text="Use an existing commit message"
      category="tertiary"
      variant="confirm"
      size="small"
      class="mr-commit-dropdown"
    >
      <gl-dropdown-item
        v-for="(commit, index) in commits"
        :key="index"
        class="text-nowrap text-truncate"
        @click="$emit('input', commit.message)"
      >
        <span class="monospace mr-2">{{ commit.shortId || commit.short_id }}</span>
        {{ commit.title }}
      </gl-dropdown-item>
    </gl-dropdown>
  </div>
</template>
