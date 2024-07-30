function vmgroupSelected(item) {
  var vmgroup = $(item).val();

  if (vmgroup === '') {
    $('#vmgroup_role_wrapper').empty();
  } else {
    var url = $(item).attr('data-url');
    var data = serializeForm().replace('method=patch', 'method=post');

    tfm.tools.showSpinner();
    $.ajax({
      type: 'post',
      url: url,
      data: data,
      error: function(jqXHR, status, error) {
        $('#vmgroup_role_wrapper').html(
          sprintf(
            __('Error loading available roles: %s'),
            error
          )
        );
        $('#compute_resource_tab a').addClass('tab-error');
      },
      success: function(result) {
        $('#vmgroup_role_wrapper').html(result);
        reloadOnAjaxComplete(item);	      
      },
    });
  }
}
