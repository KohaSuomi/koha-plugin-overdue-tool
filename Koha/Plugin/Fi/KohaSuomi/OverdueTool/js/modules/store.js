const store = new Vuex.Store({
  state: {
    basePath: '',
    results: [],
    errors: [],
    status: 'pending',
    offset: 0,
    page: 1,
    limit: 20,
    pages: 1,
    startCount: 1,
    endPage: 11,
    lastPage: 0,
    startDate: '',
    endDate: '',
    branches: [],
  },
  mutations: {
    addBasePath(state, value) {
      state.basePath = value;
    },
    addError(state, value) {
      state.errors.push(value);
    },
    removeErrors(state) {
      state.errors = [];
    },
    addResults(state, value) {
      state.results = value;
    },
    newPagesValue(state, value) {
      state.pages = value;
    },
    addStartDate(state, value) {
      state.startDate = moment(value).format('YYYY-MM-DD');
    },
    addEndDate(state, value) {
      state.endDate = moment(value).format('YYYY-MM-DD');
    },
    addOffset(state, value) {
      state.offset = value;
    },
    addPage(state, value) {
      state.page = value;
    },
    addStartCount(state, value) {
      state.startCount = value;
    },
    addLastPage(state, value) {
      state.lastPage = value;
    },
    addEndPage(state, value) {
      state.endPage = value;
    },
    addBranches(state, value) {
      state.branches = value;
    },
    increasePage(state) {
      state.page++;
    },
    increaseOffset(state) {
      state.offset = state.offset + state.limit;
    },
    decreasePage(state) {
      state.page--;
    },
    decreaseOffset(state) {
      state.offset = state.offset - state.limit;
    },
    modifyReplacementPrice(state, payload) {
      state.results.checkouts[payload.index].replacementprice = payload.value;
    },
  },
  actions: {
    fetchOverdues({ commit, state }) {
      commit('removeErrors');
      axios
        .get(state.basePath + '/checkouts/overdues', {
          params: {
            startdate: state.startDate,
            enddate: state.endDate,
            patroninfo: true,
            offset: state.offset,
            limit: state.limit,
          },
        })
        .then((response) => {
          commit('addResults', response.data.records);
          commit('newPagesValue', Math.ceil(response.data.total / state.limit));
          if (state.pages == 0) {
            commit('newPagesValue', 1);
          }
        })
        .catch((error) => {
          commit('addError', error.response.data.error);
        });
    },
    changePage({ commit, state }) {
      if (state.page < 1) {
        commit('addPage', 1);
      }
      if (state.page > state.pages) {
        commit('addPage', state.pages);
      }
      if (state.page == state.endPage) {
        commit('addStartCount', state.page);
        commit('addEndPage', state.endPage + 10);
        commit('addLastPage', state.page);
      }
      if (state.page < state.lastPage) {
        commit('addStartCount', state.page - 10);
        commit('addEndPage', state.lastPage);
        commit('addLastPage', state.lastPage - 10);
      }
    },
    setDates({ commit }, payload) {
      let today = new Date();
      let endDate = today.setDate(today.getDate() - payload.delaytime);
      commit('addEndDate', endDate);
      endDate = new Date(endDate);
      let startDate = endDate.setMonth(
        endDate.getMonth() - payload.delaymonths
      );
      commit('addStartDate', startDate);
    },
  },
  getters: {
    pageHide: (state) => {
      if (state.pages > 5) {
        if (state.endPage <= state.page && state.startCount < state.page) {
          return true;
        }
        if (state.endPage >= state.page && state.startCount > state.page) {
          return true;
        }
      }
    },
    disabledEndDates: (state) => {
      return { from: new Date(state.endDate) };
    },
  },
});

export default store;
