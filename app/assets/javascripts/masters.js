$(document).ready(function(){
  var f = $('#new_master');
  f.find('input, select').on('change', function(e){
    window.setTimeout(function(){
    f.find('input[type="submit"]').click();  
    },1);
  });

 
});