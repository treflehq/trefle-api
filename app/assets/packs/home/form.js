
// // import Vue from 'vue'
// import Buefy from 'buefy'
// import debounce from 'lodash/debounce'
// import axios from 'axios'

// if (document.querySelectorAll("#form").length > 0) {
//   Vue.use(Buefy)

//   new Vue({
//     el: "#form",
//     data() {
//         return {
//             change_type: false,
//             plant_name: '',
//             synonym_name: '',
//             plants_data: [],
//             genus_name: '',
//             genus_data: [],
//             sentence: "",
//             isSynonym: initialData.synonym_of_id ? true : false,
//             selected: null,
//             isFetching: false
//         }
//     },
//     methods: {
//         // You have to install and import debounce to use it,
//         // it's not mandatory though.
//         getAsyncData: debounce(function () {
//             if (!this.synonym_name.length) {
//                 this.plants_data = []
//                 return
//             }
//             this.isFetching = true
//             axios.get(`/api/plants?token=${USER_ACCESS_TOKEN}&q=${this.synonym_name}`)
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
//         }, 500),
//         getAsyncGenus: debounce(function () {
//             if (!this.genus_name.length) {
//                 this.genus_data = []
//                 return
//             }
//             this.isFetching = true
//             axios.get(`/api/genuses?token=${USER_ACCESS_TOKEN}&q=${this.genus_name}`)
//                 .then(({data}) => {
//                   console.log(data);
//                     this.genus_data = []
//                     data.forEach((item) => this.genus_data.push(item))
//                 })
//                 .catch((error) => {
//                     this.genus_data = []
//                     throw error
//                 })
//                 .finally(() => {
//                     this.isFetching = false
//                 })
//         }, 500)
//     }
//   })

// }
