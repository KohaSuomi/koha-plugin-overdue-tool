const patronData = Vue.component('patrondata', {
  template:
    '<div><i v-if="loader" class="fas fa-circle-notch fa-spin"></i><span v-else><span class="d-block">{{patron.surname}}, {{patron.firstname}}</span><span class="guarantorssnkey">{{guarantorssnkey}}</span></span></div>',
  props: ['borrowernumber', 'guarantorssnkey'],
  data() {
    return {
      patron: {},
      loader: true,
    };
  },
  mounted() {
    this.getPatron();
  },
  methods: {
    getPatron() {
      this.patron = {};
      axios
        .get('/api/v1/patrons/' + this.borrowernumber)
        .then((response) => {
          this.patron = response.data;
          this.loader = false;
        })
        .catch((error) => {
          this.$store.commit('addError', error.response.data.error);
          this.loader = false;
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
    createInvoice: function (letter_code, preview, all) {
      this.newcheckouts = [];
      this.newcheckouts = this.result.checkouts.slice(0);
      this.removecheckouts.forEach((element) => {
        let index = this.newcheckouts.findIndex(
          (checkout) => checkout.itemnumber === element
        );
        this.newcheckouts.splice(index, 1);
      });
      let params = {};
      params = {
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
        patronmessage: this.$store.state.patronMessage,
        guaranteemessage: this.$store.state.guaranteeMessage,
        lang: this.result.lang,
        surname: this.result.surname,
        firstname: this.result.firstname,
        cardnumber: this.result.cardnumber,
        letter_code: letter_code,
        grouplibrary: this.$store.state.groupLibrary,
        groupaddress: this.$store.state.groupAddress,
        groupcity: this.$store.state.groupCity,
        groupzipcode: this.$store.state.groupZipcode,
        groupphone: this.$store.state.groupPhone,
      };

      if (letter_code == 'EINVOICE') {
        params.letter_code = 'ODUECLAIM';
        params.message_transport_type = 'print';
      }

      if (this.result.guarantorid) {
        params.guarantee = this.result.borrowernumber;
      }
      if (preview) {
        params.preview = true;
      }
      let patronid = this.result.guarantorid
        ? this.result.guarantorid
        : this.result.borrowernumber;
      return this.$store.dispatch('sendOverdues', {
        borrowernumber: patronid,
        params: params,
        all: all,
      });
    },
    previewPDF: function (all) {
      this.createInvoice('ODUECLAIM', this.onlyPreview(), all);
      this.$parent.previewPDF(this.onlyPreview());
    },
    onlyPreview: function () {
      let retval = false;
      this.$store.state.invoiceLetters.forEach((element) => {
        if (element == 'FINVOICE' || element == 'EINVOICE') {
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
      this.result.checkouts[index].replacementprice = val.replace(/\,/g, '.');
      this.$store.dispatch('updateRepalcementPrice', {
        itemnumber: this.result.checkouts[index].itemnumber,
        replacementprice: val.replace(/\,/g, '.'),
      });
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
