const patronData = Vue.component('patrondata', {
  template: '<div>{{patron.firstname}} - {{patron.surname}}</div>',
  props: ['borrowernumber'],
  data() {
    return {
      patron: {},
    };
  },
  mounted() {
    this.getPatron();
  },
  methods: {
    getPatron() {
      axios
        .get('/api/v1/patrons/' + this.borrowernumber)
        .then((response) => {
          this.patron = response.data;
        })
        .catch((error) => {
          this.$store.commit('addError', error.response.data.error);
        });
    },
  },
});

const priceData = Vue.component('pricedata', {
  template:
    '<input type="text" :value="replacementprice | currency" v-on:change="priceChange"/>',
  props: ['replacementprice', 'index'],
  methods: {
    priceChange: function (evt) {
      this.$emit('change', evt.target.value, this.index);
    },
  },
  filters: {
    currency: function (price) {
      if (price) {
        return price.replace(/\./g, ',');
      }
    },
  },
});

const selectPrice = Vue.component('selectprice', {
  template:
    '<input type="checkbox" id="invoice" :checked="checkprice" v-on:change="selectChange">',
  props: ['itemnumber', 'replacementprice'],
  data() {
    return {
      toggle: true,
    };
  },
  mounted() {
    if (this.checkprice == false) {
      this.$parent.addRemoveCheckouts(this.itemnumber);
    }
  },
  computed: {
    checkprice() {
      var intvalue = Math.floor(this.replacementprice);
      if (intvalue == 0) {
        return false;
      } else {
        return true;
      }
    },
  },
  methods: {
    selectChange: function () {
      this.toggle = !this.toggle;
      this.$emit('change', this.toggle, this.itemnumber);
    },
  },
});

const resultList = Vue.component('result-list', {
  template: '#list-items',
  props: ['result', 'index'],
  components: {
    patronData,
    priceData,
    selectPrice,
  },
  data() {
    return {
      isActive: false,
      newcheckouts: [],
      removecheckouts: [],
    };
  },
  mounted() {
    if (this.index == 0) {
      this.activate();
    }
  },
  computed: {
    invoiceLetters() {
      return this.$store.state.invoiceLetters;
    },
    invoiced() {
      return this.$store.state.invoiced;
    },
  },
  methods: {
    activate: function () {
      this.isActive = !this.isActive;
    },
    createInvoice: function (letter_code, preview) {
      this.newcheckouts = [];
      this.newcheckouts = this.result.checkouts.slice(0);
      this.removecheckouts.forEach((element) => {
        let index = this.newcheckouts.findIndex(
          (checkout) => checkout.itemnumber === element
        );
        this.newcheckouts.splice(index, 1);
      });
      let params = {
        module: 'circulation',
        branchcode: this.$store.state.userLibrary,
        repeat_type: 'item',
        repeat: this.newcheckouts,
        notforloan_status: this.$store.state.notforloanStatus,
        debarment: this.$store.state.debarment,
        addreplacementprice: this.$store.state.addReplacementPrice,
        addreferencenumber: this.$store.state.addReferenceNumber,
        increment: this.$store.state.increment,
        invoicefine: this.$store.state.invoicefine,
        overduefines: this.$store.state.overduefines,
        librarygroup: this.$store.state.libraryGroup,
        accountnumber: this.$store.state.accountNumber,
        biccode: this.$store.state.bicCode,
        businessid: this.$store.state.businessId,
        lang: this.result.lang,
        letter_code: letter_code,
      };
      params.guarantee = this.result.borrowernumber;
      if (preview) {
        params.preview = true;
      }
      let patronid = this.result.guarantorid
        ? this.result.guarantorid
        : this.result.borrowernumber;
      this.$store.dispatch('sendOverdues', {
        borrowernumber: patronid,
        params: params,
      });
    },
    previewPDF: function () {
      this.createInvoice('ODUECLAIM', this.onlyPreview());
      this.$parent.previewPDF(this.onlyPreview());
    },
    onlyPreview: function () {
      let retval = false;
      this.$store.state.invoiceLetters.forEach((element) => {
        if (element == 'FINVOICE') {
          retval = true;
        }
      });
      return retval;
    },
    newPrice(val, index) {
      var intvalue = Math.floor(val);
      if (intvalue == 0) {
        this.addRemoveCheckouts(this.result.checkouts[index].itemnumber);
      } else {
        this.removeFromArray(
          this.removecheckouts,
          this.result.checkouts[index].itemnumber
        );
      }
      this.result.checkouts[index].replacementprice = val;
    },
    selectedPrice(val, itemnumber) {
      if (val == false) {
        this.addRemoveCheckouts(itemnumber);
      } else {
        this.removeFromArray(this.removecheckouts, itemnumber);
      }
    },
    addRemoveCheckouts(itemnumber) {
      this.removecheckouts.push(itemnumber);
    },
    removeFromArray(arr, itemnumber) {
      var ind = arr.indexOf(itemnumber);
      if (ind > -1) {
        arr.splice(ind, 1);
      }
    },
  },
  filters: {
    moment: function (date) {
      return moment(date).locale('fi').format('DD.MM.YYYY');
    },
    lowercase: function (string) {
      return string.toLowerCase();
    },
  },
});

export default resultList;
