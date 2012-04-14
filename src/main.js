require.config({
  baseUrl: "./"
});
require(["lib/jquery-1.7.2", "lib/jquery.mobile-1.1.0"], function(util) {
    //This function is called when scripts/helper/util.js is loaded.
    //If util.js calls define(), then this function is not fired until
    //util's dependencies have loaded, and the util argument will hold
    //the module value for "helper/util".
});
