$(function () {
	$('a.mark').click(function(evt) {
		evt.preventDefault();
		var a = $(this);
		var marked = a.data('marked');
		if (marked == 0) {
			$('div.unmark_all').empty().append('<a class="unmark-all" href="#"><span class="glyphicon glyphicon-remove"></span>Unmark all</a>');
			$('a.unmark-all').bind("click", function() {
			    evt.preventDefault();
		        $.post('/marked?x-tunneled-method=DELETE', function(res) {
		          $('a.mark').data('marked', 0).html('<span class="glyphicon glyphicon-ok"></span>Mark');
		          $('.unmark_all').html('');
		          $('.total-marked').text(res.total);
		        }, 'json');
		      });
			$.post('/mark/'+a.data('id'), function(res) {
				$('.total-marked').text(res.total);
				a.data('marked', 1).html('<span class="glyphicon glyphicon-remove"></span>Unmark');
			}, 'json');
		}
		else {
			$.post('/mark/'+a.data('id')+'?x-tunneled-method=DELETE', function(res) {
				$('.total-marked').text(res.total);
				a.data('marked', 0).html('<span class="glyphicon glyphicon-ok"></span>Mark');
			}, 'json');
			if($('.total-marked').text() == "1") {
				$('div.unmark_all').empty();
			}
			if(a.attr('id') && /clickme_(\d{1,})/i.test(a.attr('id'))){
				var indexes = a.attr('id').match(/clickme_\d{1,}/i);
				indexes[0] = indexes[0].replace(/clickme_/,"");
				$('#fade_' + indexes[0]).fadeOut('slow', function() {});
			}
		}
	});
});

$( document ).ready(function() {
    $.post('/marked_total', function(res) {
    	$('.total-marked').text(res.total);
    });
});