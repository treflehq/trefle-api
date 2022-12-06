
const lazy = () => {
  const config = {
    rootMargin: '0px 0px 50px 0px',
    threshold: 0
  };

  let preloadImage = (image) => {
    image.src = image.getAttribute('data-src');
  }

  // register the config object with an instance
  // of IntersectionObserver
  let observer = new IntersectionObserver(function(entries, self) {
    // iterate over each entry
    entries.forEach(entry => {
      // process just the images that are intersecting.
      // isIntersecting is a property exposed by the interface
      if(entry.isIntersecting) {
        // custom function that copies the path to the img
        // from data-src to src
        preloadImage(entry.target);
        // the image is now in place, stop watching
        self.unobserve(entry.target);
      }
    });
  }, config);

  console.log("laaazy...")
  document.addEventListener('DOMContentLoaded', () => {
    const imgs = document.querySelectorAll('[data-src]');
    imgs.forEach(img => {
      observer.observe(img);
    })
  })
}

export default lazy