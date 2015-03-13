function send () {
  var url = $(".url_field").val()
  var stream = new EventSource("/analize?url=" + encodeURIComponent(url));
  var title = "none";
  stream.addEventListener("message", function(e) {
    console.log(e.data);
  });
  stream.addEventListener("title", function(e) {
    console.log("title: " + e.data);
    title = e.data;
  });
  stream.addEventListener("result", function(e) {
    console.log("result");
    urls = JSON.parse(e.data);
    console.log(urls);
    main(urls, title);
  });
  stream.addEventListener("fail", function(e) {
    console.log("fail: " + e.data);
    show_error(e.data);
  });
  stream.addEventListener("progress_initialize", function(e) {
    progress_initialize(e.data)
  });
  stream.addEventListener("progress_set", function(e) {
    progress_set(parseFloat(e.data))
  });
  stream.addEventListener("close", function(e) {
    stream.close();
    console.log("close");
  });
  stream.addEventListener("error", function(e) {
    console.log("error");
    show_error(e.data);
    stream.close();
  });
}

fade_time = 300;

function progress_initialize (title) {
  console.log("progress_initialize: " + title);
  $(".field_container").fadeOut(fade_time, function() {
    $(".progress_title").text(title);
    NProgress.start();
    NProgress.set(0.0);
    $(".wrapper").hide();
    $(".progress_field").show();
    $(".field_container").fadeIn(fade_time);
  });
}

function progress_set (value) {
  console.log("progress_set: " + value);
  NProgress.set(value);
}

function show_download (title) {
  $(".field_container").fadeOut(fade_time, function() {
    $(".download_title").text(title + ".zip");
    $(".wrapper").hide();
    $(".download_field").show();
    $(".field_container").fadeIn(fade_time);
  });
}

function show_error (error_msg) {
  $(".field_container").fadeOut(fade_time, function() {
    $(".error_title").text(error_msg);
    $(".wrapper").hide();
    $(".error_field").show();
    $(".field_container").fadeIn(fade_time);
  });
}
