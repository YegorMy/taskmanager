define ['multiselect', 'jquery'], (multiselect, $)->
	Multiselect = ->
		$('.multiselect.dropdown-toggle').remove()
		$('select.multi').multiselect
			nonSelectedText: 'Не выбрано'
			allSelectedText: 'Выбрано всё'
			buttonContainer: '<div/>'

			buttonText: (options) ->
				if options.length == 0
					'Не выбрано' + ' ' + '<i class="fa fa-caret-down"/>'
				else
					selected = ''
					options.each ->
						label = if $(this).attr('label') != undefined then $(this).attr('label') else $(this).html()
						selected += label + ', '
						return
					selected.substr(0, selected.length - 2) + ' ' + '<i class="fa fa-caret-down"/>'
	Multiselect