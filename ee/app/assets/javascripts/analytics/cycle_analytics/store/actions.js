import Api from 'ee/api';
import createFlash from '~/flash';
import { normalizeHeaders, parseIntPagination } from '~/lib/utils/common_utils';
import httpStatus from '~/lib/utils/http_status';
import { __, sprintf } from '~/locale';
import { FETCH_VALUE_STREAM_DATA, OVERVIEW_STAGE_CONFIG } from '../constants';
import {
  removeFlash,
  throwIfUserForbidden,
  isStageNameExistsError,
  checkForDataError,
  flashErrorIfStatusNotOk,
} from '../utils';
import * as types from './mutation_types';

const appendExtension = (path) => (path.indexOf('.') > -1 ? path : `${path}.json`);

export const setPaths = ({ dispatch }, options) => {
  const { groupPath, milestonesPath = '', labelsPath = '' } = options;

  return dispatch('filters/setEndpoints', {
    labelsEndpoint: appendExtension(labelsPath),
    milestonesEndpoint: appendExtension(milestonesPath),
    groupEndpoint: groupPath,
  });
};

export const setFeatureFlags = ({ commit }, featureFlags) =>
  commit(types.SET_FEATURE_FLAGS, featureFlags);

export const setSelectedProjects = ({ commit }, projects) =>
  commit(types.SET_SELECTED_PROJECTS, projects);

export const setSelectedStage = ({ commit, getters: { paginationParams } }, stage) => {
  commit(types.SET_SELECTED_STAGE, stage);
  commit(types.SET_PAGINATION, { ...paginationParams, page: 1, hasNextPage: null });
};

export const setDateRange = (
  { commit, dispatch, getters: { isOverviewStageSelected }, state: { selectedStage } },
  { startDate, endDate },
) => {
  commit(types.SET_DATE_RANGE, { startDate, endDate });
  if (selectedStage && !isOverviewStageSelected) dispatch('fetchStageData', selectedStage.id);
  return dispatch('fetchCycleAnalyticsData');
};

export const requestStageData = ({ commit }) => commit(types.REQUEST_STAGE_DATA);

export const receiveStageDataError = ({ commit }, error) => {
  const { message = '' } = error;
  flashErrorIfStatusNotOk({
    error,
    message: __('There was an error fetching data for the selected stage'),
  });
  commit(types.RECEIVE_STAGE_DATA_ERROR, message);
};

export const fetchStageData = ({ dispatch, getters, commit }, stageId) => {
  const {
    cycleAnalyticsRequestParams = {},
    currentValueStreamId,
    currentGroupPath,
    paginationParams,
  } = getters;
  dispatch('requestStageData');

  return Api.cycleAnalyticsStageEvents({
    groupId: currentGroupPath,
    valueStreamId: currentValueStreamId,
    stageId,
    params: {
      ...cycleAnalyticsRequestParams,
      ...paginationParams,
    },
  })
    .then(checkForDataError)
    .then(({ data, headers }) => {
      const { page = null, nextPage = null } = parseIntPagination(normalizeHeaders(headers));
      commit(types.RECEIVE_STAGE_DATA_SUCCESS, data);
      commit(types.SET_PAGINATION, { ...paginationParams, page, hasNextPage: Boolean(nextPage) });
    })
    .catch((error) => dispatch('receiveStageDataError', error));
};

export const requestStageMedianValues = ({ commit }) => commit(types.REQUEST_STAGE_MEDIANS);

export const receiveStageMedianValuesError = ({ commit }, error) => {
  commit(types.RECEIVE_STAGE_MEDIANS_ERROR, error);
  createFlash({
    message: __('There was an error fetching median data for stages'),
  });
};

const fetchStageMedian = ({ groupId, valueStreamId, stageId, params }) =>
  Api.cycleAnalyticsStageMedian({ groupId, valueStreamId, stageId, params }).then(({ data }) => {
    return {
      id: stageId,
      ...(data?.error
        ? {
            error: data.error,
            value: null,
          }
        : data),
    };
  });

export const fetchStageMedianValues = ({ dispatch, commit, getters }) => {
  const {
    currentGroupPath,
    cycleAnalyticsRequestParams,
    activeStages,
    currentValueStreamId,
  } = getters;
  const stageIds = activeStages.map((s) => s.slug);

  dispatch('requestStageMedianValues');
  return Promise.all(
    stageIds.map((stageId) =>
      fetchStageMedian({
        groupId: currentGroupPath,
        valueStreamId: currentValueStreamId,
        stageId,
        params: cycleAnalyticsRequestParams,
      }),
    ),
  )
    .then((data) => commit(types.RECEIVE_STAGE_MEDIANS_SUCCESS, data))
    .catch((error) => dispatch('receiveStageMedianValuesError', error));
};

export const requestCycleAnalyticsData = ({ commit }) => commit(types.REQUEST_VALUE_STREAM_DATA);

export const receiveCycleAnalyticsDataSuccess = ({ commit, dispatch }) => {
  commit(types.RECEIVE_VALUE_STREAM_DATA_SUCCESS);
  dispatch('typeOfWork/fetchTopRankedGroupLabels');
};

export const receiveCycleAnalyticsDataError = ({ commit }, { response = {} }) => {
  const { status = httpStatus.INTERNAL_SERVER_ERROR } = response;

  commit(types.RECEIVE_VALUE_STREAM_DATA_ERROR, status);
  if (status !== httpStatus.FORBIDDEN) {
    createFlash({
      message: __('There was an error while fetching value stream analytics data.'),
    });
  }
};

export const fetchCycleAnalyticsData = ({ dispatch }) => {
  removeFlash();

  return Promise.resolve()
    .then(() => dispatch('requestCycleAnalyticsData'))
    .then(() => dispatch('fetchValueStreams'))
    .then(() => dispatch('receiveCycleAnalyticsDataSuccess'))
    .catch((error) => {
      return Promise.all([
        dispatch('receiveCycleAnalyticsDataError', error),
        dispatch('durationChart/setLoading', false),
        dispatch('typeOfWork/setLoading', false),
      ]);
    });
};

export const requestGroupStages = ({ commit }) => commit(types.REQUEST_GROUP_STAGES);

export const receiveGroupStagesError = ({ commit }, error) => {
  commit(types.RECEIVE_GROUP_STAGES_ERROR, error);
  createFlash({
    message: __('There was an error fetching value stream analytics stages.'),
  });
};

export const setDefaultSelectedStage = ({ dispatch }) =>
  dispatch('setSelectedStage', OVERVIEW_STAGE_CONFIG);

export const receiveGroupStagesSuccess = ({ commit }, stages) =>
  commit(types.RECEIVE_GROUP_STAGES_SUCCESS, stages);

export const fetchGroupStagesAndEvents = ({ dispatch, getters }) => {
  const {
    currentValueStreamId: valueStreamId,
    currentGroupPath: groupId,
    cycleAnalyticsRequestParams: { created_after, project_ids },
  } = getters;

  dispatch('requestGroupStages');
  dispatch('customStages/setStageEvents', []);

  return Api.cycleAnalyticsGroupStagesAndEvents({
    groupId,
    valueStreamId,
    params: {
      start_date: created_after,
      project_ids,
    },
  })
    .then(({ data: { stages = [], events = [] } }) => {
      dispatch('receiveGroupStagesSuccess', stages);
      dispatch('customStages/setStageEvents', events);
    })
    .catch((error) => {
      throwIfUserForbidden(error);
      return dispatch('receiveGroupStagesError', error);
    });
};

export const requestUpdateStage = ({ commit }) => commit(types.REQUEST_UPDATE_STAGE);
export const receiveUpdateStageSuccess = ({ commit, dispatch }, updatedData) => {
  commit(types.RECEIVE_UPDATE_STAGE_SUCCESS);
  createFlash({
    message: __('Stage data updated'),
    type: 'notice',
  });
  return Promise.resolve()
    .then(() => dispatch('fetchGroupStagesAndEvents'))
    .then(() => dispatch('customStages/showEditForm', updatedData))
    .catch(() => {
      createFlash({
        message: __('There was a problem refreshing the data, please try again'),
      });
    });
};

export const receiveUpdateStageError = (
  { commit, dispatch },
  { status, responseData: { errors = null } = {}, data = {} },
) => {
  commit(types.RECEIVE_UPDATE_STAGE_ERROR, { errors, data });

  const { name = null } = data;
  const message =
    name && isStageNameExistsError({ status, errors })
      ? sprintf(__(`'%{name}' stage already exists`), { name })
      : __('There was a problem saving your custom stage, please try again');

  createFlash({
    message: __(message),
  });
  return dispatch('customStages/setStageFormErrors', errors);
};

export const updateStage = ({ dispatch, getters }, { id, ...params }) => {
  const { currentGroupPath, currentValueStreamId } = getters;

  dispatch('requestUpdateStage');
  dispatch('customStages/setSavingCustomStage');

  return Api.cycleAnalyticsUpdateStage({
    groupId: currentGroupPath,
    valueStreamId: currentValueStreamId,
    stageId: id,
    data: params,
  })
    .then(({ data }) => dispatch('receiveUpdateStageSuccess', data))
    .catch(({ response: { status = httpStatus.BAD_REQUEST, data: responseData } = {} }) =>
      dispatch('receiveUpdateStageError', { status, responseData, data: { id, ...params } }),
    );
};

export const requestRemoveStage = ({ commit }) => commit(types.REQUEST_REMOVE_STAGE);
export const receiveRemoveStageSuccess = ({ commit, dispatch }) => {
  commit(types.RECEIVE_REMOVE_STAGE_RESPONSE);
  createFlash({
    message: __('Stage removed'),
    type: 'notice',
  });
  return dispatch('fetchCycleAnalyticsData');
};

export const receiveRemoveStageError = ({ commit }) => {
  commit(types.RECEIVE_REMOVE_STAGE_RESPONSE);
  createFlash({
    message: __('There was an error removing your custom stage, please try again'),
  });
};

export const removeStage = ({ dispatch, getters }, stageId) => {
  const { currentGroupPath, currentValueStreamId } = getters;
  dispatch('requestRemoveStage');

  return Api.cycleAnalyticsRemoveStage({
    groupId: currentGroupPath,
    valueStreamId: currentValueStreamId,
    stageId,
  })
    .then(() => dispatch('receiveRemoveStageSuccess'))
    .catch((error) => dispatch('receiveRemoveStageError', error));
};

export const initializeCycleAnalyticsSuccess = ({ commit }) =>
  commit(types.INITIALIZE_VALUE_STREAM_SUCCESS);

export const initializeCycleAnalytics = ({ dispatch, commit }, initialData = {}) => {
  commit(types.INITIALIZE_VSA, initialData);

  const {
    featureFlags = {},
    milestonesPath,
    labelsPath,
    selectedAuthor,
    selectedMilestone,
    selectedAssigneeList,
    selectedLabelList,
    stage: selectedStage,
    group,
  } = initialData;
  commit(types.SET_FEATURE_FLAGS, featureFlags);

  if (group?.fullPath) {
    return Promise.all([
      selectedStage
        ? dispatch('setSelectedStage', selectedStage)
        : dispatch('setDefaultSelectedStage'),
      dispatch('setPaths', { groupPath: group.fullPath, milestonesPath, labelsPath }),
      dispatch('filters/initialize', {
        selectedAuthor,
        selectedMilestone,
        selectedAssigneeList,
        selectedLabelList,
      }),
      dispatch('durationChart/setLoading', true),
      dispatch('typeOfWork/setLoading', true),
    ])
      .then(() =>
        Promise.all([
          selectedStage?.id ? dispatch('fetchStageData', selectedStage.id) : Promise.resolve(),
          dispatch('fetchCycleAnalyticsData'),
        ]),
      )
      .then(() => dispatch('initializeCycleAnalyticsSuccess'));
  }

  return dispatch('initializeCycleAnalyticsSuccess');
};

export const requestReorderStage = ({ commit }) => commit(types.REQUEST_REORDER_STAGE);

export const receiveReorderStageSuccess = ({ commit }) =>
  commit(types.RECEIVE_REORDER_STAGE_SUCCESS);

export const receiveReorderStageError = ({ commit }) => {
  commit(types.RECEIVE_REORDER_STAGE_ERROR);
  createFlash({
    message: __('There was an error updating the stage order. Please try reloading the page.'),
  });
};

export const reorderStage = ({ dispatch, getters }, initialData) => {
  dispatch('requestReorderStage');
  const { currentGroupPath, currentValueStreamId } = getters;
  const { id, moveAfterId, moveBeforeId } = initialData;

  const params = moveAfterId ? { move_after_id: moveAfterId } : { move_before_id: moveBeforeId };

  return Api.cycleAnalyticsUpdateStage({
    groupId: currentGroupPath,
    valueStreamId: currentValueStreamId,
    stageId: id,
    data: params,
  })
    .then(({ data }) => dispatch('receiveReorderStageSuccess', data))
    .catch(({ response: { status = httpStatus.BAD_REQUEST, data: responseData } = {} }) =>
      dispatch('receiveReorderStageError', { status, responseData }),
    );
};

export const receiveCreateValueStreamSuccess = ({ commit, dispatch }, valueStream = {}) => {
  commit(types.RECEIVE_CREATE_VALUE_STREAM_SUCCESS, valueStream);
  return dispatch('fetchCycleAnalyticsData');
};

export const createValueStream = ({ commit, dispatch, getters }, data) => {
  const { currentGroupPath } = getters;
  commit(types.REQUEST_CREATE_VALUE_STREAM);

  return Api.cycleAnalyticsCreateValueStream(currentGroupPath, data)
    .then(({ data: newValueStream }) => dispatch('receiveCreateValueStreamSuccess', newValueStream))
    .catch(({ response } = {}) => {
      const { data: { message, payload: { errors } } = null } = response;
      commit(types.RECEIVE_CREATE_VALUE_STREAM_ERROR, { message, errors, data });
    });
};

export const updateValueStream = (
  { commit, dispatch, getters },
  { id: valueStreamId, ...data },
) => {
  const { currentGroupPath } = getters;
  commit(types.REQUEST_UPDATE_VALUE_STREAM);

  return Api.cycleAnalyticsUpdateValueStream({ groupId: currentGroupPath, valueStreamId, data })
    .then(({ data: newValueStream }) => {
      commit(types.RECEIVE_UPDATE_VALUE_STREAM_SUCCESS, newValueStream);
      return dispatch('fetchCycleAnalyticsData');
    })
    .catch(({ response } = {}) => {
      const { data: { message, payload: { errors } } = null } = response;
      commit(types.RECEIVE_UPDATE_VALUE_STREAM_ERROR, { message, errors, data });
    });
};

export const deleteValueStream = ({ commit, dispatch, getters }, valueStreamId) => {
  const { currentGroupPath } = getters;
  commit(types.REQUEST_DELETE_VALUE_STREAM);

  return Api.cycleAnalyticsDeleteValueStream(currentGroupPath, valueStreamId)
    .then(() => commit(types.RECEIVE_DELETE_VALUE_STREAM_SUCCESS))
    .then(() => dispatch('fetchCycleAnalyticsData'))
    .catch(({ response } = {}) => {
      const { data: { message } = null } = response;
      commit(types.RECEIVE_DELETE_VALUE_STREAM_ERROR, message);
    });
};

export const fetchValueStreamData = ({ dispatch }) =>
  Promise.resolve()
    .then(() => dispatch('fetchGroupStagesAndEvents'))
    .then(() => dispatch('fetchStageMedianValues'))
    .then(() => dispatch('durationChart/fetchDurationData'));

export const setSelectedValueStream = ({ commit, dispatch }, valueStream) => {
  commit(types.SET_SELECTED_VALUE_STREAM, valueStream);
  return dispatch(FETCH_VALUE_STREAM_DATA);
};

export const receiveValueStreamsSuccess = (
  { state: { selectedValueStream = null }, commit, dispatch },
  data = [],
) => {
  commit(types.RECEIVE_VALUE_STREAMS_SUCCESS, data);
  if (!selectedValueStream && data.length) {
    const [firstStream] = data;
    return dispatch('setSelectedValueStream', firstStream);
  }
  return dispatch(FETCH_VALUE_STREAM_DATA);
};

export const fetchValueStreams = ({ commit, dispatch, getters }) => {
  const { currentGroupPath } = getters;

  commit(types.REQUEST_VALUE_STREAMS);

  return Api.cycleAnalyticsValueStreams(currentGroupPath)
    .then(({ data }) => dispatch('receiveValueStreamsSuccess', data))
    .catch((error) => {
      const {
        response: { status },
      } = error;
      commit(types.RECEIVE_VALUE_STREAMS_ERROR, status);
      throw error;
    });
};

export const setFilters = ({
  dispatch,
  getters: { isOverviewStageSelected },
  state: { selectedStage },
}) => {
  if (selectedStage && !isOverviewStageSelected) dispatch('fetchStageData', selectedStage.id);
  return dispatch('fetchCycleAnalyticsData');
};

export const updateStageTablePagination = (
  { commit, dispatch, state: { selectedStage } },
  paginationParams,
) => {
  commit(types.SET_PAGINATION, paginationParams);
  return dispatch('fetchStageData', selectedStage.id);
};
