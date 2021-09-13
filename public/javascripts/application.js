$(function() {
  
  $("form.delete").submit(function(event) { 
    event.preventDefault();
    event.stopPropagation();
    
    var ok = confirm("This cannot be undone - click OK to confirm deletion.");
    if (ok) { 
      this.submit();
    }
    
  });
  
});