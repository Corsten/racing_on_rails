jQuery(document).ready(function() {
  jQuery('.competition_enabled').click(
    function() {
      var id = jQuery(this).data('competition-id');
      var enabled = jQuery(this).data('enabled');
      jQuery(this).data('enabled', !enabled);
      jQuery.ajax({
        type: 'POST',
        url: '/admin/competitions/' + id + '.js',
        data: { '_method': 'PATCH', competition: { enabled: !enabled } }
      });
    });
});
