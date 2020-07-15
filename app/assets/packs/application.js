/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb


// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)

import './application.scss'

require("@rails/ujs").start()

import Typed from 'typed.js';
require('@fortawesome/fontawesome-pro/js/all.js');

// import "./fa/brands.min.js";
// import "./fa/regular.min.js";
// import "./fa/fontawesome.min.js";
import "./home/admin.js";
import "./home/home.js";
import "./home/codesandbox.js";
// import "./home/form-select.js";
// import "./home/form.js";
// import "./reference.js";

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

// import socket from "./socket"
// console.log("Hello");
// if (document.querySelectorAll(".typed-in").length > 0) {
//   // console.log("World");
//   var options = {
//     strings: [
//       'Browse all plants in the world ?^1000<code>curl <a href="https://trefle.io/api/v1/plants">trefle.io/api/v1/plants</a></code>^1000\n\n' +
//       'Search a very specific plant ?^1000<code>curl <a href="https://trefle.io/api/v1/plants/search?q=pomegranate">trefle.io/api/v1/plants?q=pomegranate</a></code>^1000'
//     ],
//     typeSpeed: 40,
//     backSpeed: 10,
//     // cursorChar: '🁢',
//     smartBackspace: true
//   }

//   var typed = new Typed(".typed-in", options);
// }

document.addEventListener('DOMContentLoaded', () => {

  // Get all "navbar-burger" elements
  const $navbarBurgers = Array.prototype.slice.call(document.querySelectorAll('.navbar-burger'), 0);

  // Check if there are any navbar burgers
  if ($navbarBurgers.length > 0) {

    // Add a click event on each of them
    $navbarBurgers.forEach(el => {
      el.addEventListener('click', () => {

        // Get the target from the "data-target" attribute
        const target = el.dataset.target;
        const $target = document.getElementById(target);

        // Toggle the "is-active" class on both the "navbar-burger" and the "navbar-menu"
        el.classList.toggle('is-active');
        $target.classList.toggle('is-active');

      });
    });
  }

});
