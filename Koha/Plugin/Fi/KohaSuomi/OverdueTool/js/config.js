const Multiselect = Vue.component(
  'vue-multiselect',
  window.VueMultiselect.default
);

new Vue({
  el: '#configApp',
  components: {
    Multiselect,
  },
  data() {
    return {
      errors: [],
      groupname: '',
      groupLibraries: [],
      selectedLibraries: [],
      invoicelibrary: '',
      delaymonths: 0,
      maxyears: 1,
      invoicenotforloan: null,
      groupsettings: [],
      group: {},
      showGroup: false,
      saved: false,
      invoiceTypes: [
        { name: 'Finvoice', value: 'FINVOICE' },
        { name: 'E-lasku', value: 'EINVOICE' },
        { name: 'PDF-lasku', value: 'ODUECLAIM' },
      ],
      invoiceLibraries: [
        { name: 'Lainaajakirjasto', value: 'issuebranch' },
        { name: 'Omistajakirjasto', value: 'itembranch' },
      ],
    };
  },
  created() {
    this.getConfig();
  },
  computed: {},
  methods: {
    getConfig() {
      axios
        .get('/api/v1/contrib/kohasuomi/overdues/config')
        .then((response) => {
          console.log(response.data);
          this.groupLibraries = response.data.libraries;
          this.invoicelibrary = response.data.invoicelibrary;
          this.delaymonths = response.data.delaymonths;
          this.maxyears = response.data.maxyears;
          this.invoicenotforloan = response.data.invoicenotforloan;
          this.groupsettings = response.data.groupsettings;
        })
        .catch((error) => {
          this.errors.push(error.response.data.error);
        });
    },
    setConfig() {
      this.saved = false;
      let index = this.groupsettings.findIndex(
        (group) => group.groupname === this.group.groupname
      );
      if (index > -1) {
        this.groupsettings[index] = this.group;
      } else {
        if (Object.keys(this.group).length !== 0) {
          this.groupsettings.push(this.group);
        }
      }
      axios
        .put('/api/v1/contrib/kohasuomi/overdues/config', {
          invoicelibrary: this.invoicelibrary,
          delaymonths: this.delaymonths,
          maxyears: this.maxyears,
          invoicenotforloan: this.invoicenotforloan,
          debarment: this.debarment,
          addreplacementprice: this.addreplacementprice,
          groupsettings: JSON.stringify(this.groupsettings),
        })
        .then(() => {
          this.saved = true;
          this.showGroup = false;
        })
        .catch((error) => {
          this.errors.push(error.response.data.error);
        });
    },
    createGroup() {
      this.group = {};
      this.group.groupname = this.groupname;
      this.groupname = '';
      this.showGroup = true;
    },
    updateGroup(e, group) {
      e.preventDefault();
      this.group = group;
      this.showGroup = true;
    },
    removeGroup() {
      let index = this.groupsettings.findIndex(
        (group) => group.groupname === this.group.groupname
      );
      if (index > -1) {
        this.groupsettings.splice(index, 1);
      }
      this.clearGroup();
    },
    clearGroup() {
      this.group = {};
      this.showGroup = false;
    },
  },
});
