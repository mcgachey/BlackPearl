//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require_tree .

var ready = function(){
  $("#course_policy_id").change(function(){
    $.get("/policy/" + this.value + "/text", {}, function(data) {
      div = document.getElementById("policy_body_div")
      div.innerHTML = data
    })
  })
};

$(document).on('page:load', ready)

$(document).ready(ready)
