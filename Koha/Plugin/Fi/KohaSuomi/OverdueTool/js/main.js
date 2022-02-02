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
      pdfBtn: false,
      einvoiceBtn: false,
      finvoiceBtn: false,
      previewBtn: false,
      categoryfilter: '',
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
    store.commit('addGroupLibrary', jsondata.grouplibrary);
    store.commit('addGroupAddress', jsondata.groupaddress);
    store.commit('addGroupCity', jsondata.groupcity);
    store.commit('addGroupZipcode', jsondata.groupzipcode);
    store.commit('addGroupPhone', jsondata.groupphone);
    store.dispatch('setDates', jsondata.overduerules);
    this.selectCategory = jsondata.overduerules.categorycodes;
    this.fetch();
    const sumFilter = localStorage.getItem('sumFilter');
    if (sumFilter) {
      this.sumFilter = sumFilter;
    }
  },
  computed: {
    results() {
      return store.getters.filterResultsBySum(
        this.sumFilter,
        this.categoryfilter
      );
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
    created() {
      return store.state.created;
    },
  },
  methods: {
    fetch() {
      store.commit('setCreated', false);
      store.dispatch('fetchOverdues');
      this.activate();
    },
    previewPDF(preview, all) {
      if (!all) {
        store.commit('setNotice', '');
      }
      this.preview = preview;
      this.showPDF = true;
    },
    async allFinvoices() {
      if (this.$refs.resultComponentRef) {
        this.finvoiceBtn = true;
        store.commit('setCreated', false);
        await Promise.all(
          this.$refs.resultComponentRef.map(async (element) => {
            await element.createInvoice('FINVOICE', false, true);
          })
        ).then(() => {
          this.finvoiceBtn = false;
          store.commit('setCreated', true);
        });
      }
    },
    async allPDFs(preview) {
      if (this.$refs.resultComponentRef) {
        store.commit('setNotice', '');
        if (preview) {
          this.previewBtn = true;
        } else {
          this.pdfBtn = true;
        }
        store.commit('setCreated', false);
        await Promise.all(
          this.$refs.resultComponentRef.map(async (element) => {
            await element.createInvoice('ODUECLAIM', preview, true);
          })
        ).then(() => {
          this.previewPDF(preview, true);
          if (preview) {
            this.previewBtn = false;
          } else {
            this.pdfBtn = false;
          }
          store.commit('setCreated', true);
        });
      }
    },
    async allEinvoices() {
      if (this.$refs.resultComponentRef) {
        this.einvoiceBtn = true;
        store.commit('setCreated', false, true);
        await Promise.all(
          this.$refs.resultComponentRef.map(async (element) => {
            await element.createInvoice('EINVOICE', false);
          })
        ).then(() => {
          this.einvoiceBtn = false;
          store.commit('setCreated', true);
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
      store.commit('setCreated', false);
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
      store.commit('invoiced', e.target.checked);
      this.fetch();
    },
    onCategoryChange(e) {
      this.categoryfilter = e.target.value;
    },
    filterResults(e) {
      this.buttonLoader = false;
      localStorage.setItem('sumFilter', e.target.value);
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
