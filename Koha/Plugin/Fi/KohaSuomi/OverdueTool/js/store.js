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
    disableDate: '',
    libraries: [],
    invoiceLibrary: '',
    maxYears: 1,
    lastDate: '',
    invoiceType: '',
    userLibrary: '',
    libraryGroup: '',
    notforloanStatus: '',
    invoiced: false,
    debarment: false,
    addReferenceNumber: false,
    categorycodes: [],
    resultOffset: 0,
    showLoader: false,
    notice: '',
    increment: '',
    invoicefine: '',
    accountNumber: '',
    bicCode: '',
    messageId: '',
    businessId: '',
    patronMessage: '',
    guaranteeMessage: '',
    created: false,
    groupLibrary: '',
    groupAddress: '',
    groupCity: '',
    groupZipcode: '',
    groupPhone: '',
    invoiceNumber: 0,
    cancelToken: null,
    blockedGuarantors: [],
    guarantorDebarment: false
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
    addDisableDate(state, value) {
      state.disableDate = moment(value).format('YYYY-MM-DD');
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
    addInvoiceLibrary(state, value) {
      state.invoiceLibrary = value;
    },
    addMaxYears(state, value) {
      state.maxYears = value;
    },
    addInvoiceType(state, value) {
      state.invoiceType = value;
    },
    addUserLibrary(state, value) {
      state.userLibrary = value;
    },
    addLibraryGroup(state, value) {
      state.libraryGroup = value;
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
    debarment(state, value) {
      state.debarment = value;
    },
    invoiced(state, value) {
      state.invoiced = value;
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
    modifyResults(state, payload) {
      state.results[payload.index] = payload.value;
    },
    setNotice(state, value) {
      state.notice = '';
      state.notice = value;
    },
    setNotices(state, value) {
      state.notice += value;
      state.notice += '<div style="page-break-after: always;"></div>';
    },
    setMessageId(state, value) {
      state.messageId = value;
    },
    setCreated(state, value) {
      state.created = value;
    },
    addGroupLibrary(state, value) {
      state.groupLibrary = value;
    },
    addGroupAddress(state, value) {
      state.groupAddress = value;
    },
    addGroupCity(state, value) {
      state.groupCity = value;
    },
    addGroupZipcode(state, value) {
      state.groupZipcode = value;
    },
    addGroupPhone(state, value) {
      state.groupPhone = value;
    },
    addInvoiceNumber(state, value) {
      state.invoiceNumber = value;
    },
    addCancelToken(state, value) {
      state.cancelToken = value;
    },
    addBlockedGuarantors(state, value) {
      state.blockedGuarantors = value;
    },
    addGuarantorDebarment(state, value) {
      state.guarantorDebarment = value;
    }
  },
  actions: {
    setSettings({ dispatch, commit, state }, payload) {
      commit('addInvoiceLibrary', payload.invoicelibrary);
      commit('addMaxYears', payload.maxyears);
      commit('addUserLibrary', payload.userlibrary);
      commit('addNotForLoanStatus', payload.invoicenotforloan);
      commit('addInvoiceNumber', payload.invoicenumber);
      payload.groupsettings.forEach((group) => {
        group.grouplibraries.forEach((lib) => {
          if (lib.branchcode == state.userLibrary) {
            let libArray = group.grouplibraries.map(function (obj) {
              return obj.branchcode;
            });
            commit('addLibraries', libArray);
            commit('addInvoiceType', group.invoicetype);
            if (group.debarment) {
              commit('debarment', group.debarment);
            }
            if (group.addreferencenumber) {
              commit('addReferenceNumber', group.addreferencenumber);
            }
            commit('addInvoiceFine', group.invoicefine);
            commit('addLibraryGroup', group.groupname);
            commit('addIncrement', group.increment);
            commit('addAccountNumber', group.accountnumber);
            commit('addBicCode', group.biccode);
            commit('addBusinessId', group.businessid);
            commit('addPatronMessage', group.patronmessage);
            commit('addGuaranteeMessage', group.guaranteemessage);
            commit('addGroupLibrary', group.grouplibrary);
            commit('addGroupAddress', group.groupaddress);
            commit('addGroupZipcode', group.groupzipcode);
            commit('addGroupCity', group.groupcity);
            commit('addGroupPhone', group.groupphone);
            if (group.guarantorblock) {
              let blockedArr = group.guarantorblock.split(',');
              commit('addBlockedGuarantors', blockedArr);
            }
            if (group.guarantordebarment) {
              commit('addGuarantorDebarment', group.guarantordebarment);
            }
          }
        });
      });
      commit('addCategoryCodes', payload.overduerules.categorycodes);
      dispatch('setDates', payload.overduerules);
    },
    fetchOverdues({ dispatch, commit, state }) {
      if (state.cancelToken) {
        state.cancelToken.cancel(); 
      }
      commit("addCancelToken", axios.CancelToken.source());
      commit('addResults', []);
      commit('addOffset', 0);
      commit('removeErrors');
      commit('showLoader', true);
      var searchParams = new URLSearchParams();
      searchParams.set('startdate', state.startDate);
      searchParams.set('enddate', state.endDate);
      searchParams.set('invoicelibrary', state.invoiceLibrary);
      searchParams.set('lastdate', state.lastDate);
      searchParams.set('categorycodes', state.categorycodes);
      searchParams.set('invoicedstatus', state.notforloanStatus);
      searchParams.set('invoiced', state.invoiced);
      searchParams.set('libraries', state.libraries);
      searchParams.set('offset', state.offset);
      searchParams.set('sort', 'borrowernumber');
      searchParams.set('limit', 1);

      axios
        .get('/api/v1/contrib/kohasuomi/overdues', {
          cancelToken: state.cancelToken.token,
          params: searchParams,
        })
        .then((response) => {
          commit('addTotalResults', response.data.total);
          commit('newPagesValue', Math.ceil(response.data.total / state.limit));
          dispatch('fetchAllOverdues');
        })
        .catch((error) => {
          let err = error.message;
          if (error.response.data.error) {
            err += ':' + error.response.data.error;
          } else {
            err += ', check the logs';
          }
          commit('addError', err);
        });
    },
    async fetchAllOverdues({ commit, state }) {
      var searchParams = new URLSearchParams();
      searchParams.set('startdate', state.startDate);
      searchParams.set('enddate', state.endDate);
      searchParams.set('invoicelibrary', state.invoiceLibrary);
      searchParams.set('lastdate', state.lastDate);
      searchParams.set('categorycodes', state.categorycodes);
      searchParams.set('invoicedstatus', state.notforloanStatus);
      searchParams.set('invoiced', state.invoiced);
      searchParams.set('libraries', state.libraries);
      searchParams.set('sort', 'borrowernumber');
      searchParams.set('limit', 5);
      const promises = [];
      let offset = 0;
      for (let i = 0; i < state.pages; i++) {
        searchParams.set('offset', offset);
        offset = offset + 5;
        if (offset == state.offset) {
          continue;
        }
        promises.push(
          axios
            .get('/api/v1/contrib/kohasuomi/overdues', {
              cancelToken: state.cancelToken.token,
              params: searchParams,
            })
            .then((response) => {
              response.data.records.forEach((element) => {
                if (offset == state.offset) {
                  commit('pushResults', element);
                }
              });
            })
            .catch((error) => {
              let err = error.message;
              if (error.response.data.error) {
                err += ':' + error.response.data.error;
              } else {
                err += ', check the logs';
              }
              commit('addError', err);
            })
        );
        commit('addOffset', offset);
      }
      await Promise.all(promises).then(() => {
        commit('showLoader', false);
      });
    },
    async sendOverdues({ dispatch, commit }, payload) {
      commit('showLoader', true);
      commit('removeErrors');
      commit('setCreated', false);
      return axios
        .post(
          '/api/v1/contrib/kohasuomi/invoices/' + payload.borrowernumber,
          payload.params
        )
        .then((response) => {
          if (payload.all && payload.params.message_transport_type == 'pdf') {
            commit('setNotices', response.data.notice);
            commit('setMessageId', response.data.message_id);
          } else if (payload.all) {
            commit('setNotice', response.data.notice);
            commit('setMessageId', response.data.message_id);
          } else {
            commit('setNotice', response.data.notice);
            commit('setMessageId', response.data.message_id);
            commit('setCreated', true);
          }
          if (
            !payload.params.preview &&
            payload.params.message_transport_type == 'pdf'
          ) {
            dispatch('editNotice', 'sent');
          }
          commit('showLoader', false);
        })
        .catch((error) => {
          let err = error.message;
          if (error.response.data.error) {
            err += ': ' + error.response.data.error;
          } else {
            err += ', check the logs';
          }
          commit('addError', err);
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
      if (!state.disableDate) {
        commit('addDisableDate', endDate);
      }
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
        .put('/api/v1/contrib/kohasuomi/notices/' + state.messageId + '/invoice', { status: status })
        .then(() => {
          commit('showLoader', false);
        })
        .catch((error) => {
          let err = error.message;
          if (error.response.data.error) {
            err += ':' + error.response.data.error;
          } else {
            err += ', check the logs';
          }
          commit('addError', err);
        });
    },
    updateReplacementPrice({ commit }, payload) {
      commit('removeErrors');
      axios
        .patch('/api/v1/contrib/kohasuomi/items/' + payload.itemnumber, {
          replacementprice: payload.replacementprice,
        })
        .then(() => {})
        .catch((error) => {
          let err = error.message;
          if (error.response.data.error) {
            err += ':' + error.response.data.error;
          } else {
            err += ', check the logs';
          }
          commit('addError', err);
        });
    },
  },
  getters: {
    addTotalItems: (state) => () => {
      let total = 0;
      state.results.forEach((patron) => {
        patron.checkouts.forEach((checkout) => {
          total++;
        });
      });
      return total;
    },
    addTotalSum: (state) => () => {
      let total = 0;
      state.results.forEach((patron) => {
        patron.checkouts.forEach((checkout) => {
          if(checkout.replacementprice == null){
            checkout.replacementprice = 0;
          }
          total += parseFloat(checkout.replacementprice);
        });
      });
      return total.toFixed(2).replace(".", ",");
    },
    disabledEndDates: (state) => {
      return { from: new Date(state.disableDate) };
    },
    filterResultsBySum: (state) => (minimumSum, categoryfilter) => {
      let filteredResults = [];
      let min = minimumSum;
      const sumFilter = localStorage.getItem('sumFilter');
      if (sumFilter) {
        min = sumFilter;
      }
      state.results.forEach((patron) => {
        if (categoryfilter && categoryfilter != patron.categorycode) {
          return;
        }
        let sum = 0;
        patron.checkouts.forEach((checkout) => {
          if (checkout.replacementprice) {
            sum += Math.round(checkout.replacementprice);
          }
        });
        if (sum >= min) {
          filteredResults.push(patron);
        }
      });
      return filteredResults;
    },
    filterLetters: (state) => {
      let letters = state.invoiceLetters;
      let remove = false;
      let odueindex;
      for (let i = 0; i < letters.length; i++) {
        if (letters[i] == 'FINVOICE' || letters[i] == 'EINVOICE') {
          remove = true;
        }
        if (letters[i] == 'ODUECLAIM') {
          odueindex = i;
        }
      }
      if (remove) {
        letters.splice(odueindex, 1);
      }
      return letters;
    },
  },
});

export default store;
