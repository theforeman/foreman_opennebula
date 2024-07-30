function schedulerHintFilterSelected(item) {
  var scheduler_hint_filter = $(item).val();

  if (scheduler_hint_filter === '') {
    $('#scheduler_hint_data_wrapper').empty();
  } else {
    var url = $(item).attr('data-url');
    var data = serializeForm().replace('method=patch', 'method=post');

    tfm.tools.showSpinner();
    $.ajax({
      type: 'post',
      url: url,
      data: data,
      error: function(jqXHR, status, error) {
        $('#scheduler_hint_data_wrapper').html(
          sprintf(
            __('Error loading scheduler hint filters information: %s'),
            error
          )
        );
        $('#compute_resource_tab a').addClass('tab-error');
      },
      success: function(result) {
        $('#scheduler_hint_data_wrapper').html(result);
	reloadOnAjaxComplete(item);
      },
    });
  }
}
