function method_aggregation(sentence) {
  $.mobile.loading('show');
  $("#submit-btn").button("disable");
  
  var start = new Date();
  var result = null;
  
  jQuery.ajax({
    url: "/aggr/positive_word/" + escape(sentence) + ".json?" + vodafone_please_stop_caching_everything(),
    success: function(data) {
      $.mobile.loading('hide');
      $("#submit-btn").button("enable");
      if (data["highest_positive_sentiment_word"]==null || data["highest_positive_sentiment_word"]==undefined) {
        $("#results").prepend("<div class='result-par result'><div class='result-time-par'>AJAX Async API requests: " + (new Date() - start) + " ms</div><div class='result-data'>Sentence has no positive emotional value at all</div></div>");
      }
      else {
        $("#results").prepend("<div class='result-aggr result'><div class='result-time-aggr'>Aggregated API requests: " + (new Date() - start) + " ms</div><div class='result-data'>" + JSON.stringify(data["highest_positive_sentiment_word"])  + "</div></div>");
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
