(function ($) {
    $.fn.extend({
        center: function () {
            return this.each(function () {
		var currentPos = $(this).position().top;
                var scrollBottom = $(window).scrollTop() + window.innerHeight;
                var parent = $(this).parent();
                var parentPos = parent.position();
                var top = (parent.height() > window.innerHeight) ? window.innerHeight : parent.height();
                top -= $(this).outerHeight();
                top = top / 2 + document.body.scrollTop;
				var adj = 30;
                var position = (top > parentPos.top ? top : parentPos.top) + adj;
                position = (position - adj < parentPos.top + parent.height() ? position : parentPos.top + parent.height()) - adj;
                if(position != currentPos) {
                    $(this).parent().children().children('.centerable').center();
                }
                $(this).css({
                    position: 'absolute',
                    margin: 0,
                    top: position + 'px'
                });
            });
        }
    });
})(jQuery);

$('.acttitle').center();
$(window).scroll(function () {
    $('.acttitle').center();
});
