new Vue({
  el: '#configApp',
  data() {
    return {
      errors: [],
      invoicelibrary: jsondata.invoicelibrary,
      delaymonths: jsondata.delaymonths,
      maxyears: jsondata.maxyears,
      invoicenotforloan: jsondata.invoicenotforloan,
      debarment: jsondata.debarment,
      addreplacementprice: jsondata.addreplacementprice,
      referencenumbersettings: jsondata.referencenumbersettings,
      saved: false,
    };
  },
  mounted() {},
  computed: {},
  methods: {
    save() {
      this.saved = false;
      var url = new URL(window.location.href);
      url.searchParams.set('method', 'api');
      axios
        .get(url.href, {
          params: {
            invoicelibrary: this.invoicelibrary,
            delaymonths: this.delaymonths,
            maxyears: this.maxyears,
            invoicenotforloan: this.invoicenotforloan,
            debarment: this.debarment,
            addreplacementprice: this.addreplacementprice,
            referencenumbersettings: JSON.stringify(
              this.referencenumbersettings
            ),
          },
        })
        .then(() => {
          this.saved = true;
        })
        .catch((error) => {
          this.errors.push(error.response.data.error);
        });
    },
  },
});
