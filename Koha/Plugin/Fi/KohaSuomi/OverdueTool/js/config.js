new Vue({
  el: '#configApp',
  data() {
    return {
      errors: [],
      invoicelibrary: jsondata.invoicelibrary,
      delaymonths: jsondata.delaymonths,
      maxyears: jsondata.maxyears,
      invoicenotforloan: jsondata.invoicenotforloan,
      groupsettings: jsondata.groupsettings,
      saved: false,
    };
  },
  mounted() {},
  computed: {},
  methods: {
    save() {
      this.saved = false;
      var url = new URL(window.location.href);
      // url.searchParams.set('method', 'api');
      axios
        .post(url.href, {
          method: 'api',
          class: 'Koha::Plugin::Fi::KohaSuomi::OverdueTool',
          params: {
            invoicelibrary: this.invoicelibrary,
            delaymonths: this.delaymonths,
            maxyears: this.maxyears,
            invoicenotforloan: this.invoicenotforloan,
            debarment: this.debarment,
            addreplacementprice: this.addreplacementprice,
            groupsettings: JSON.stringify(this.groupsettings),
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
