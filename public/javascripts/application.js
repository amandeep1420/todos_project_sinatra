$(function() {
  
  $("form.delete").submit(function(event) { 
    event.preventDefault();
    event.stopPropagation();
    
    var ok = confirm("This cannot be undone - click OK to confirm deletion.");
    if (ok) { 
      var form = $(this);
      
      var request = $.ajax({
        url: form.attr("action"),
        method: form.attr("method"),
      });
      
      request.done(function(data, textStatus, jqXHR) { 
        if (jqXHR == 204) {
          form.parent("li").remove()
      } else if (jqXHR == 200) {
          document.location = data;
      }
    });
    }
  });
  
});