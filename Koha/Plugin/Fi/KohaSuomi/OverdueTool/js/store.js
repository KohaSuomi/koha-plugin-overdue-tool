const store = new Vuex.Store({
  state: {
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
    totalResults: 0,
    startDate: '',
    endDate: '',
    libraries: [],
    invoiceLibrary: '',
    maxYears: 1,
    lastDate: '',
    invoiceLetters: [],
    userLibrary: '',
    notforloanStatus: '',
    invoiced: false,
    debarment: '',
    addReplacementPrice: '',
    addReferenceNumber: '',
    libraryGroup: '',
    categorycodes: [],
    resultOffset: 0,
    showLoader: false,
    notice: '',
    increment: '',
  },
  mutations: {
    addError(state, value) {
      state.errors.push(value);
    },
    removeErrors(state) {
      state.errors = [];
    },
    addResults(state, value) {
      state.results = value;
    },
    addTotalResults(state, value) {
      state.totalResults = value;
    },
    addResultOffset(state, value) {
      state.resultOffset = value;
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
    addLastDate(state, value) {
      state.lastDate = moment(value).format('YYYY-MM-DD');
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
    addLibraries(state, value) {
      state.libraries = value;
    },
    addLibraryGroup(state, value) {
      state.libraryGroup = value;
    },
    addInvoiceLibrary(state, value) {
      state.invoiceLibrary = value;
    },
    addMaxYears(state, value) {
      state.maxYears = value;
    },
    addInvoiceLetters(state, value) {
      state.invoiceLetters = value;
    },
    addUserLibrary(state, value) {
      state.userLibrary = value;
    },
    addNotForLoanStatus(state, value) {
      state.notforloanStatus = value;
    },
    addCategoryCodes(state, value) {
      state.categorycodes = value;
    },
    debarment(state, value) {
      state.debarment = value;
    },
    invoiced(state, value) {
      state.invoiced = value;
    },
    addReplacementPrice(state, value) {
      state.addReplacementPrice = value;
    },
    addIncrement(state, value) {
      state.increment = value;
    },
    addReferenceNumber(state, value) {
      state.addReferenceNumber = value;
    },
    showLoader(state, value) {
      state.showLoader = value;
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
    setNotice(state, value) {
      state.notice = '';
      state.notice += value;
    },
  },
  actions: {
    fetchOverdues({ commit, state }) {
      commit('removeErrors');
      commit('showLoader', true);
      var searchParams = new URLSearchParams();
      searchParams.append('startdate', state.startDate);
      searchParams.append('enddate', state.endDate);
      searchParams.append('invoicelibrary', state.invoiceLibrary);
      searchParams.append('lastdate', state.lastDate);
      searchParams.append('categorycodes', state.categorycodes);
      searchParams.append('invoicedstatus', state.notforloanStatus);
      searchParams.append('invoiced', state.invoiced);
      searchParams.append('libraries', state.libraries);
      searchParams.append('offset', state.offset);
      searchParams.append('limit', state.limit);

      axios
        .get('/api/v1/checkouts/overdues', {
          params: searchParams,
        })
        .then((response) => {
          commit('addResults', response.data.records);
          commit('addTotalResults', response.data.total);
          commit('newPagesValue', Math.ceil(response.data.total / state.limit));

          if (response.data.records.length < state.limit) {
            commit(
              'addResultOffset',
              state.offset + response.data.records.length
            );
          } else {
            commit(
              'addResultOffset',
              response.data.records.length * state.page
            );
          }
          if (state.pages == 0) {
            commit('newPagesValue', 1);
          }
          commit('showLoader', false);
        })
        .catch((error) => {
          commit('addError', error.response.data.error);
        });
    },
    sendOverdues({ commit, state }, payload) {
      commit('removeErrors');
      axios
        .post('/api/v1/invoices/' + payload.borrowernumber, payload.params)
        .then((response) => {
          commit('setNotice', response.data.notice);
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
    setDates({ commit, state }, payload) {
      let today = new Date();
      let endDate = today.setDate(today.getDate() - payload.delaytime);
      commit('addEndDate', endDate);
      endDate = new Date(endDate);
      let startDate = endDate.setMonth(
        endDate.getMonth() - payload.delaymonths
      );
      commit('addStartDate', startDate);
      let lastDate = endDate.setYear(endDate.getFullYear() - state.maxYears);
      commit('addLastDate', lastDate);
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
