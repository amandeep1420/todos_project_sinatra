$(function() {
  
  $("form.delete").submit(function(event) { 
    event.preventDefault();
    event.stopPropagation();
    
    var ok = confirm("This cannot be undone - click OK to confirm deletion.");
    if (ok) { 
      
      var form = $(this);
      
      $.ajax({
        url: form.attr("action"),
        method: form.attr("method"),
      });
    }
  });
  
});