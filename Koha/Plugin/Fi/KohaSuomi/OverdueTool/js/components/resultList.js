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
  methods: {
    activate: function () {
      this.isActive = !this.isActive;
    },
    createInvoice: function () {
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
        lang: this.result.lang,
      };
      params.guarantee = this.result.borrowernumber;
      let patronid = this.result.guarantorid
        ? this.result.guarantorid
        : this.result.borrowernumber;
      this.$store.dispatch('sendOverdues', {
        borrowernumber: patronid,
        params: params,
      });
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
  },
});

export default resultList;
