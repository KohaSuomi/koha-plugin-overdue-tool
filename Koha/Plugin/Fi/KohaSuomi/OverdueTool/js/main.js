import store from './store.js';
import resultlist from './components/resultList.js';

new Vue({
  el: '#viewApp',
  store: store,
  components: {
    vuejsDatepicker,
    resultlist,
  },
  data() {
    return {
      fi: vdp_translation_fi.js,
      showPDF: false,
    };
  },
  mounted() {
    store.commit('addInvoiceLibrary', jsondata.invoicelibrary);
    store.commit('addMaxYears', jsondata.maxyears);
    store.commit('addLibraries', jsondata.libraries);
    store.commit('addInvoiceLetters', jsondata.invoiceletters);
    store.commit('addUserLibrary', jsondata.userlibrary);
    store.commit('addNotForLoanStatus', jsondata.invoicenotforloan);
    store.commit('debarment', jsondata.debarment);
    store.commit('addReplacementPrice', jsondata.addreplacementprice);
    store.commit('addReferenceNumber', jsondata.addreferencenumber);
    store.commit('addIncrement', jsondata.increment);
    store.commit('addLibraryGroup', jsondata.librarygroup);
    store.commit('addCategoryCodes', jsondata.overduerules.categorycodes);
    store.dispatch('setDates', jsondata.overduerules);
    this.fetch();
  },
  computed: {
    results() {
      return store.state.results;
    },
    totalResults() {
      return store.state.totalResults;
    },
    resultOffset() {
      return store.state.resultOffset;
    },
    offset() {
      return store.state.offset;
    },
    errors() {
      return store.state.errors;
    },
    status() {
      return store.state.status;
    },
    showLoader() {
      return store.state.showLoader;
    },
    page() {
      return store.state.page;
    },
    limit() {
      return store.state.limit;
    },
    pages() {
      return store.state.pages;
    },
    startCount() {
      return store.state.startCount;
    },
    endPage() {
      return store.state.endPage;
    },
    lastPage() {
      return store.state.lastPage;
    },
    startDate() {
      return store.state.startDate;
    },
    endDate() {
      return store.state.endDate;
    },
    pageHide() {
      return store.getters.pageHide;
    },
    disabledEndDates() {
      return store.getters.disabledEndDates;
    },
    invoiced() {
      return store.state.invoiced;
    },
    notice() {
      return store.state.notice;
    },
  },
  methods: {
    fetch() {
      store.dispatch('fetchOverdues');
      this.activate();
    },
    previewPDF() {
      this.showPDF = true;
    },
    printPDF() {
      printJS({
        printable: 'printDoc',
        type: 'html',
        css: '/plugin/Koha/Plugin/Fi/KohaSuomi/OverdueTool/css/pdf.css',
      });
    },
    back() {
      this.showPDF = false;
    },
    updateStartDate(value) {
      store.commit('addStartDate', value);
      this.fetch();
    },
    updateEndDate(value) {
      store.commit('addEndDate', value);
      this.fetch();
    },
    increasePage() {
      if (this.page != this.pages) {
        store.commit('increasePage');
        store.commit('increaseOffset');
        this.fetch();
      }
    },
    decreasePage() {
      if (this.page != 1) {
        store.commit('decreasePage');
        store.commit('decreaseOffset');
        this.fetch();
      }
    },
    changeInvoiced(e) {
      if (this.invoiced == false) {
        store.commit('invoiced', true);
      } else {
        store.commit('invoiced', false);
      }
      this.fetch();
    },
    changePage(e, page) {},
    activate() {
      $('.page-link').removeClass('bg-primary text-white');
      $('[data-current=' + this.page + ']').addClass('bg-primary text-white');
    },
  },
});
