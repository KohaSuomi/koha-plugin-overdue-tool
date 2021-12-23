const store = new Vuex.Store({
  state: {
    results: [],
    errors: [],
    offset: 0,
    page: 1,
    limit: 5,
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
    invoicefine: '',
    overduefines: '',
    accountNumber: '',
    bicCode: '',
    messageId: '',
    businessId: '',
    patronMessage: '',
    guaranteeMessage: '',
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
    pushResults(state, value) {
      state.results.push(value);
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
    addInvoiceFine(state, value) {
      state.invoicefine = value;
    },
    addOverdueFines(state, value) {
      state.overduefines = value;
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
    addAccountNumber(state, value) {
      state.accountNumber = value;
    },
    addBicCode(state, value) {
      state.bicCode = value;
    },
    addBusinessId(state, value) {
      state.businessId = value;
    },
    addPatronMessage(state, value) {
      state.patronMessage = value;
    },
    addGuaranteeMessage(state, value) {
      state.guaranteeMessage = value;
    },
    showLoader(state, value) {
      state.showLoader = value;
    },
    increaseOffset(state) {
      state.offset = state.offset + state.limit;
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
    setMessageId(state, value) {
      state.messageId = value;
    },
  },
  actions: {
    fetchOverdues({ dispatch, commit, state }) {
      commit('addResults', []);
      commit('addOffset', 0);
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
      searchParams.append('sort', 'borrowernumber');
      searchParams.append('limit', 1);

      axios
        .get('/api/v1/checkouts/overdues', {
          params: searchParams,
        })
        .then((response) => {
          commit('addTotalResults', response.data.total);
          commit('newPagesValue', Math.ceil(response.data.total / state.limit));
          dispatch('fetchAllOverdues');
        })
        .catch((error) => {
          commit('addError', error.response.data.error);
        });
    },
    async fetchAllOverdues({ commit, state }) {
      var searchParams = new URLSearchParams();
      searchParams.append('startdate', state.startDate);
      searchParams.append('enddate', state.endDate);
      searchParams.append('invoicelibrary', state.invoiceLibrary);
      searchParams.append('lastdate', state.lastDate);
      searchParams.append('categorycodes', state.categorycodes);
      searchParams.append('invoicedstatus', state.notforloanStatus);
      searchParams.append('invoiced', state.invoiced);
      searchParams.append('libraries', state.libraries);
      searchParams.append('sort', 'borrowernumber');
      searchParams.append('limit', 5);
      const promises = [];
      let offset = 0;
      for (let i = 0; i < state.pages; i++) {
        searchParams.append('offset', offset);
        promises.push(
          axios
            .get('/api/v1/checkouts/overdues', {
              params: searchParams,
            })
            .then((response) => {
              response.data.records.forEach((element) => {
                commit('pushResults', element);
              });
            })
            .catch((error) => {
              commit('addError', error.response.data.error);
            })
        );
        offset = offset + 5;
      }
      await Promise.all(promises).then(() => {
        commit('showLoader', false);
      });
    },
    sendOverdues({ commit, state }, payload) {
      commit('showLoader', true);
      commit('removeErrors');
      axios
        .post('/api/v1/invoices/' + payload.borrowernumber, payload.params)
        .then((response) => {
          commit('setNotice', response.data.notice);
          commit('setMessageId', response.data.message_id);
          commit('showLoader', false);
        })
        .catch((error) => {
          commit('addError', error.response.data.error);
        });
    },
    changePage({ commit, state }, payload) {
      let selectedPage = payload;

      commit('addPage', selectedPage);
      if (selectedPage < 1) {
        commit('addPage', 1);
      }
      if (selectedPage > state.pages) {
        commit('addPage', state.pages);
      }

      let countValue = state.limit * (state.page - 1);
      if (selectedPage == 1) {
        commit('addOffset', 0);
      } else {
        commit('addOffset', countValue);
      }
    },
    showPages({ commit, state }, payload) {
      if (payload == state.endPage) {
        commit('addStartCount', payload);
        commit('addEndPage', state.endPage + 10);
        commit('addLastPage', payload);
      }
      if (payload < state.lastPage) {
        commit('addStartCount', payload - 10);
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
    editNotice({ commit, state }, status) {
      commit('showLoader', true);
      commit('removeErrors');
      axios
        .put('/api/v1/notices/' + state.messageId, { status: status })
        .then(() => {
          commit('showLoader', false);
        })
        .catch((error) => {
          commit('addError', error.response.data.error);
        });
    },
  },
  getters: {
    disabledEndDates: (state) => {
      return { from: new Date(state.endDate) };
    },
    filterResultsBySum: (state) => (minimumSum) => {
      let filteredResults = [];
      state.results.forEach((patron) => {
        let sum = 0;
        patron.checkouts.forEach((checkout) => {
          if (checkout.replacementprice) {
            sum += Math.round(checkout.replacementprice);
          }
        });
        if (sum >= minimumSum) {
          filteredResults.push(patron);
        }
      });
      return filteredResults;
    },
  },
});

export default store;
