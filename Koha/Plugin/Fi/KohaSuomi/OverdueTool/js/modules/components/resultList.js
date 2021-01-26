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
        .get(this.$store.state.basePath + '/patrons/' + this.borrowernumber)
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
  data() {
    return {
      price: '',
    };
  },
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
    '<input type="checkbox" id="invoice" checked v-on:change="selectChange">',
  props: ['itemnumber'],
  data() {
    return {
      toggle: true,
    };
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
        letter_code: 'ODUECLAIM',
        branchcode: 'JOE_JOE',
        repeat_type: 'item',
        repeat: this.newcheckouts,
      };
      axios
        .post(
          this.$store.state.basePath +
            '/invoices/' +
            this.result.borrowernumber,
          params
        )
        .then((response) => {
          console.log(response);
        })
        .catch((error) => {
          console.log(error);
          this.$store.commit('addError', error.response.data.error);
        });
    },
    newPrice(val, index) {
      this.result.checkouts[index].replacementprice = val;
    },
    selectedPrice(val, index) {
      if (val == false) {
        this.removecheckouts.push(index);
      } else {
        this.removeFromArray(this.removecheckouts, index);
      }
    },
    removeFromArray(arr, index) {
      var ind = arr.indexOf(index);
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
