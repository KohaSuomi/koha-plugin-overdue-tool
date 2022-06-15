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
    this.getConfig();
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
    invoiceType() {
      return store.state.invoiceType;
    },
    created() {
      return store.state.created;
    },
  },
  methods: {
    getConfig() {
      axios
        .get('/api/v1/contrib/kohasuomi/overdues/config')
        .then((response) => {
          store.dispatch('setSettings', response.data);
          this.selectCategory = response.data.overduerules.categorycodes;
          const sumFilter = localStorage.getItem('sumFilter');
          if (sumFilter) {
            this.sumFilter = sumFilter;
          }
          const pluginVersion = localStorage.getItem('invoicePluginVersion');
          if (pluginVersion != response.data.pluginversion) {
            $('#reloadModal').modal('show');
            localStorage.setItem(
              'invoicePluginVersion',
              response.data.pluginversion
            );
          }
          this.fetch();
        })
        .catch((error) => {
          console.log(error);
          store.commit('addErrors', error.response.data.error);
        });
    },
    fetch() {
      store.commit('setCreated', false);
      store.dispatch('fetchOverdues');
      this.activate();
    },
    async refreshInvoiceNumber() {
      return axios
        .get('/api/v1/contrib/kohasuomi/overdues/config')
        .then((response) => {
          store.commit('addInvoiceNumber', response.data.invoicenumber);
        })
        .catch((error) => {
          store.commit('addErrors', error.response.data.error);
        });
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
        await this.refreshInvoiceNumber();
        this.finvoiceBtn = true;
        store.commit('setCreated', false);
        this.refreshInvoiceNumber();
        await Promise.all(
          this.$refs.resultComponentRef.map(async (element) => {
            await element.createInvoice(false, true);
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
          await this.refreshInvoiceNumber();
          this.pdfBtn = true;
        }
        store.commit('setCreated', false);
        await Promise.all(
          this.$refs.resultComponentRef.map(async (element) => {
            await element.createInvoice(preview, true);
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
        await this.refreshInvoiceNumber();
        this.einvoiceBtn = true;
        store.commit('setCreated', false, true);
        await Promise.all(
          this.$refs.resultComponentRef.map(async (element) => {
            await element.createInvoice(false, false);
          })
        ).then(() => {
          this.einvoiceBtn = false;
          store.commit('setCreated', true);
        });
      }
    },
    printPDF() {
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
