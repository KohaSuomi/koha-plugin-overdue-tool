import store from "./modules/store.js";
import resultlist from "./modules/components/resultList.js";

new Vue({
  el: "#viewApp",
  store: store,
  components: {
    vuejsDatepicker,
    resultlist,
  },
  data() {
    return {
      fi: vdp_translation_fi.js,
    };
  },
  mounted() {
    store.commit("addBasePath", jsondata.endpointpath);
    store.commit("addBranches", jsondata.branches);
    store.dispatch("setDates", jsondata.overduerules);
    this.fetch();
  },
  computed: {
    results() {
      return store.state.results;
    },
    errors() {
      return store.state.errors;
    },
    status() {
      return store.state.status;
    },
    isActive() {
      return store.state.isActive;
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
  },
  methods: {
    setBasePath(path) {
      store.commit("addBasePath", path);
    },
    fetch() {
      store.dispatch("fetchOverdues");
      this.activate();
    },
    updateStartDate(value) {
      store.commit("addStartDate", value);
      this.fetch();
    },
    updateEndDate(value) {
      store.commit("addEndDate", value);
      this.fetch();
    },
    increasePage() {
      if (this.page != this.pages) {
        store.commit("increasePage");
        store.commit("increaseOffset");
        this.fetch();
      }
    },
    decreasePage() {
      if (this.page != 1) {
        store.commit("decreasePage");
        store.commit("decreaseOffset");
        this.fetch();
      }
    },
    changePage(e, page) {},
    activate() {
      $(".page-link").removeClass("bg-primary text-white");
      $("[data-current=" + this.page + "]").addClass("bg-primary text-white");
    },
  },
});
