function main (urls, title) {
  var worker = new Worker("/js/worker.js");
  worker.postMessage({"urls" : urls});
  var downloaded_count = 0;
  progress_initialize("画像をダウンロード中...");
  worker.addEventListener('message', function(event) {
    var command = event.data.command;
    if(command == 'download') {
      var filename = event.data.filename;
      downloaded_count += 1;
      console.log(filename);
      progress_set(downloaded_count / urls.length);
    }
    if(command == 'complete') {
      var blob = event.data.blob;
      var $a = $('.download_button');
      $a.attr('href', window.URL.createObjectURL(blob));
      $a.attr('download', title + ".zip");
      show_download(title);
      worker.terminate();
    }
  });
}
