var global = self;
importScripts("/js/jszip.min.js");
importScripts("/js/promise-6.1.0.min.js");

var zip = new JSZip();

self.addEventListener('message', function (event) {
  var urls = event.data.urls;
  urls = urls.map(function(v) {
    return "/geturl?url=" + encodeURIComponent(v);
  });
  arr = []
  for(var i = 0; i < urls.length; i++) {
    arr.push(i);
  }
  var promises = arr.map(function (i) {
    return new Promise(function (resolve, reject) {
      var xhr = new XMLHttpRequest();
      xhr.open("GET", urls[i]);
      xhr.responseType = "arraybuffer";

      xhr.onload = function (event) {
        var arrayBuffer = xhr.response;
        var filename = ("000" + i).substr(-3, 3) + urls[i].match(/\.(jpg|jpeg|png|gif)/)[0];
        zip.file(filename, arrayBuffer, { binary: true });
        postMessage({
          command: 'download',
          filename: filename
        });
        resolve(true);
      };
      xhr.onerror = function (event) {
        resolve(false);
      };
      xhr.send();
    });
  });
  Promise.all(promises).then(function () {
    postMessage({
      command: 'complete',
      blob: zip.generate({ type: "blob" })
    });
  });
});
