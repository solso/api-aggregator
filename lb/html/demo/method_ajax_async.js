function method_ajax_async(sentence) {
  $.mobile.loading('show');
  $("#submit-btn").button("disable");
  
  var start = new Date();
  var result = null;
  var current_max = Number.NEGATIVE_INFINITY;
  var max_sentiment = 5;
  var num_req = 0;
  var max_word = null;
  
  jQuery.ajax({
    url: "/v1/sentence/" + escape(sentence) + ".json?" + vodafone_please_stop_caching_everything(),
    success: function(data) {
      result = data;
      if (result["sentiment"]>0) {
        var words = sentence.split(" ");
        for(var i=0;i<words.length;i++) {
          if (words[i]!=null && words[i].length>3) {
            num_req++;
            jQuery.ajax({
              url: "/v1/word/" + escape(words[i]) + ".json?" + vodafone_please_stop_caching_everything(),
              success: function(data) {
                current_word = data;
                num_req--;
                if (current_word!=null && current_word["sentiment"]>current_max) {
                  current_max = current_word["sentiment"];
                  max_word = current_word;
                }
                if (num_req==0) {
                  $.mobile.loading('hide');
                  $("#submit-btn").button("enable");
                  
                  $("#results").prepend("<div class='result-par result'><div class='result-time-par'>AJAX Async API requests: " + (new Date() - start) + " ms</div><div class='result-data'>" + JSON.stringify(max_word) + "</div></div>");
                }
              },
              error: function() {
                $.mobile.loading('hide');
                $("#submit-btn").button("enable");
                $("#results").prepend("<div class='result-error result'>Woops! Please try again later.</div>");
              },
              async:true,
              dataType:"json"
            });
          }
        }
      }  
      else {
        $.mobile.loading('hide');
        $("#submit-btn").button("enable");
        $("#results").prepend("<div class='result-par result'><div class='result-time-par'>AJAX Async API requests: " + (new Date() - start) + " ms</div><div class='result-data'>Sentence has no positive emotional value at all</div></div>");
      }
    },
    error: function() {
      $.mobile.loading('hide');
      $("#submit-btn").button("enable");
      $("#results").prepend("<div class='result-error result'>Woops! Please try again later.</div>");
    },
    async:true,
    dataType:"json"            
  });
}      
