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
      preview: true,
      selectCategory: [],
      showFilters: false,
      sumFilter: 10,
      buttonLoader: false,
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
    store.commit('addInvoiceFine', jsondata.invoicefine);
    store.commit('addOverdueFines', jsondata.overduefines);
    store.commit('addIncrement', jsondata.increment);
    store.commit('addLibraryGroup', jsondata.librarygroup);
    store.commit('addAccountNumber', jsondata.accountnumber);
    store.commit('addBicCode', jsondata.biccode);
    store.commit('addBusinessId', jsondata.businessid);
    store.commit('addPatronMessage', jsondata.patronmessage);
    store.commit('addGuaranteeMessage', jsondata.guaranteemessage);
    store.commit('addCategoryCodes', jsondata.overduerules.categorycodes);
    store.dispatch('setDates', jsondata.overduerules);
    this.selectCategory = jsondata.overduerules.categorycodes;
    this.fetch();
  },
  computed: {
    results() {
      return store.getters.filterResultsBySum(this.sumFilter);
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
    disabledEndDates() {
      return store.getters.disabledEndDates;
    },
    invoiced() {
      return store.state.invoiced;
    },
    notice() {
      return store.state.notice;
    },
    invoiceLetters() {
      return store.state.invoiceLetters;
    },
  },
  methods: {
    fetch() {
      store.dispatch('fetchOverdues');
      this.activate();
    },
    previewPDF(preview) {
      this.preview = preview;
      this.showPDF = true;
    },
    async allFinvoices() {
      if (this.$refs.resultComponentRef) {
        this.buttonLoader = true;
        await Promise.all(
          this.$refs.resultComponentRef.map(async (element) => {
            await element.createInvoice('FINVOICE', false);
          })
        ).then(() => {
          this.buttonLoader = false;
        });
      }
    },
    async allPDFs() {
      if (this.$refs.resultComponentRef) {
        store.commit('showLoader', true);
        this.previewPDF(true);
        await Promise.all(
          this.$refs.resultComponentRef.map(async (element) => {
            await element.createInvoice(
              'ODUECLAIM',
              element.onlyPreview(),
              true
            );
          })
        ).then(() => {
          store.commit('showLoader', false);
        });
      }
    },
    async allEinvoices() {
      if (this.$refs.resultComponentRef) {
        this.buttonLoader = true;
        await Promise.all(
          this.$refs.resultComponentRef.map(async (element) => {
            await element.createInvoice('EINVOICE', false);
          })
        ).then(() => {
          this.buttonLoader = false;
        });
      }
    },
    printPDF() {
      if (!this.preview) {
        store.dispatch('editNotice', 'sent');
      }
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
    changeInvoiced(e) {
      if (this.invoiced == false) {
        store.commit('invoiced', true);
      } else {
        store.commit('invoiced', false);
      }
      this.fetch();
    },
    onCategoryChange(e) {
      store.commit('addCategoryCodes', [e.target.value]);
      this.fetch();
    },
    filterResults(e) {
      this.sumFilter = e.target.value;
    },
    toggleFilters() {
      this.showFilters = !this.showFilters;
    },
    activate() {
      $('.page-link').removeClass('bg-primary text-white');
      $('[data-current=' + this.page + ']').addClass('bg-primary text-white');
    },
  },
});
