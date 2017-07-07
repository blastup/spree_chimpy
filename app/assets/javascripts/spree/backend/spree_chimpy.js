//= require spree/backend
$(document).ready(function () {
  'use strict';
  if($('#chimpy-subscribed').is(':checked')) {
    $('#chimpy-subscribed-list-container').show();
  }

  $(document).on('change', "#chimpy-subscribed", function () {
    if($(this).is(':checked')) {
      $('#chimpy-subscribed-list-container').fadeIn();
    } else {
      $('#chimpy-subscribed-list-container').fadeOut();
    }
  });
});