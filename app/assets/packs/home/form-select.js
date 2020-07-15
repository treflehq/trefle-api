
// // import Vue from 'vue'
// import Buefy from 'buefy'
// import debounce from 'lodash/debounce'
// import axios from 'axios'

// if (document.querySelectorAll("#form-select").length > 0) {
//   Vue.use(Buefy)

//   new Vue({
//     el: "#form-select",
//     data() {
//         return {
//             change_type: false,
//             plant_name: '',
//             plants_data: [],
//             sentence: "",
//             selected: null,
//             isFetching: false
//         }
//     },
//     watch: {
//       change_type: function() {
//         switch (this.change_type) {
//           case "correction":
//             this.sentence = `Correct`
//             break;
//           case "completion":
//             this.sentence = `Complete`
//             break;
//           default:
//             this.sentence = ""
//         }
//       }
//     },
//     methods: {
//         // You have to install and import debounce to use it,
//         // it's not mandatory though.
//         needSpeciesId: function () {
//           return this.change_type == "completion" || this.change_type == "correction"
//         },
//         perform: function () {
//           window.location = `/species_proposals/${this.change_type}/${this.selected.id}`
//         },
//         setAddition: function () {
//           this.change_type = "addition"
//           window.location = "/species_proposals/addition"
//         },
//         setCorrection: function () {
//           this.change_type = "correction"
//           console.log("setCorrection");
//         },
//         setCompletion: function () {
//           this.change_type = "completion"
//           console.log("setCompletion");
//         },
//         getAsyncData: debounce(function () {
//             if (!this.plant_name.length) {
//                 this.plants_data = []
//                 return
//             }
//             this.isFetching = true
//             axios.get(`/api/plants?token=${USER_ACCESS_TOKEN}&q=${this.plant_name}`)
//                 .then(({data}) => {
//                   console.log(data);
//                     this.plants_data = []
//                     data.forEach((item) => this.plants_data.push(item))
//                 })
//                 .catch((error) => {
//                     this.plants_data = []
//                     throw error
//                 })
//                 .finally(() => {
//                     this.isFetching = false
//                 })
//         }, 500)
//     }
//   })
//   var element = document.getElementById("form-select");
//   element.classList.remove("is-invisible");

// }
