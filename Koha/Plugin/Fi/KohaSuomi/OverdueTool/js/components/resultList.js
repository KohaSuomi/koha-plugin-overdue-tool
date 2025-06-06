const patronData = Vue.component('patrondata', {
  template:
    '<div><i v-if="loader" class="fas fa-circle-notch fa-spin"></i><span v-else><span class="d-block">{{patron.surname}}, {{patron.firstname}} ({{guarantorssnkey}})</span><span class="d-block">{{patron.address}}, {{patron.zipcode}} {{patron.city}}</span></span></div>',
  props: ['borrowernumber', 'guarantorssnkey'],
  data() {
    return {
      patron: {},
      loader: true,
      borrowernumber: "",
    };
  },
  watch: {
    borrowernumber: function borrowernumber(new_val, old_val) {
      if( new_val != old_val ){
        this.loader = true;
        this.getPatron();
      }
    }
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
          let err = error.message;
          if (error.response.data.error) {
            err += ':' + error.response.data.error;
          } else {
            err += ', check the logs';
          }
          commit('addError', err);
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
        return price.toString().replace(/\./g, ',');
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
      disableButton: false,
      patronErrors: [],
    };
  },
  mounted() {
    // Fetch the state disabling "Create button"
    this.disableButton = sessionStorage.getItem("disableButton"+this.index);
    if (this.index == 0) {
      this.activate();
    }
    this.validatePatron();
    if (this.errors.length) {
      this.disableInvoiceButton();
    }
  },
  computed: {
    errors() {
      return this.$store.state.errors;
    },
    invoiceType() {
      return this.$store.state.invoiceType;
    },
    invoiced() {
      return this.$store.state.invoiced;
    },
    invoicenumber() {
      return parseInt(this.$store.state.invoiceNumber);
    },
  },
  methods: {
    disableInvoiceButton: function () {
      this.disableButton = true;
      // Save the state of disabling "Create" button
      sessionStorage.setItem("disableButton"+this.index, true);
    },
    activate: function () {
      this.isActive = !this.isActive;
    },
    validatePatron: function () {
      const fields = ['surname', 'address', 'zipcode', 'city'];
      const finnishFields = ['sukunimi', 'osoite', 'postinumero', 'kaupunki'];
      this.patronErrors = [];
      fields.forEach((field) => {
        if (!this.result[field]) {
          this.disableInvoiceButton();
          this.patronErrors.push(finnishFields[fields.indexOf(field)]);
        }
      });
    },
    create: function () {
      if (this.invoiceType === 'FINVOICE' || this.invoiceType === 'EINVOICE') {
        this.createInvoice(false);
      } else {
        this.previewPDF(false);
      }
    },
    createInvoice: function (preview, all) {
      if (this.patronErrors.length && !preview) {
        return "error";
      }
      if (!preview) {
        this.disableInvoiceButton();
        this.$store.commit('addInvoiceNumber', this.invoicenumber+1);
      }
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
        addreferencenumber: this.$store.state.addReferenceNumber,
        increment: this.$store.state.increment,
        invoicefine: this.$store.state.invoicefine,
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
        invoicenumber: this.$store.state.invoiceNumber,
        letter_code: 'ODUECLAIM',
        grouplibrary: this.$store.state.groupLibrary,
        groupaddress: this.$store.state.groupAddress,
        groupcity: this.$store.state.groupCity,
        groupzipcode: this.$store.state.groupZipcode,
        groupphone: this.$store.state.groupPhone,
        guarantordebarment: this.$store.state.guarantorDebarment
      };

      if (this.invoiceType == 'FINVOICE' && !preview) {
        params.message_transport_type = 'finvoice';
      } else if (this.invoiceType == 'EINVOICE' && !preview) {
        params.message_transport_type = 'print';
      } else {
        params.message_transport_type = 'pdf';
      }

      if (this.result.guarantorid && !this.$store.state.blockedGuarantors.some(data => data === this.result.categorycode)) {
        params.guarantee = this.result.borrowernumber;
      } else if (this.result.guarantorid && this.$store.state.blockedGuarantors.some(data => data === this.result.categorycode)) {
        params.guarantor = this.result.guarantorid;
      }

      if (preview) {
        params.preview = true;
      }
      let patronid = this.result.guarantorid && !this.$store.state.blockedGuarantors.some(data => data === this.result.categorycode)
        ? this.result.guarantorid
        : this.result.borrowernumber;
      if (this.newcheckouts.length) {
        return this.$store.dispatch('sendOverdues', {
          borrowernumber: patronid,
          params: params,
          all: all,
        });
      }
    },
    previewPDF: function (preview, all) {
      this.createInvoice(preview, all);
      this.$parent.previewPDF(preview);
    },
    invoiceCopy: function () {
      const guarantor_id = this.result.guarantorid && !this.$store.state.blockedGuarantors.some(data => data === this.result.categorycode) ? this.result.guarantorid : undefined;
      this.$store.dispatch('getInvoiceCopy', {patron_id: this.result.borrowernumber, guarantor_id: guarantor_id, multi: false});
      this.$parent.previewPDF(true);
    },
    invoiceCopies: function () {
      const guarantor_id = this.result.guarantorid && !this.$store.state.blockedGuarantors.some(data => data === this.result.categorycode) ? this.result.guarantorid : undefined;
      return this.$store.dispatch('getInvoiceCopy', {patron_id: this.result.borrowernumber, guarantor_id: guarantor_id, multi: true});
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
      this.$store.dispatch('updateReplacementPrice', {
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
