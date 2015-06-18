define ['datepicker', 'jquery'], (datepicker, $)->
	DatePicker = ->
		$('form .datepicker').datetimepicker
			locale: 'ru'


	DatePicker