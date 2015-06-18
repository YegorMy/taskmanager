define ['jquery'], ($)->
	Select = (element = null)->
		unless element

			$('.noconflict-replaced').remove()
			element = $('select.replace')
		else
			element.next().remove()


		element.each ->
			$div         = $('<div/>').addClass('dropdown noconflict-replaced')
			$ul          = $('<ul/>').addClass 'dropdown-menu'
			$this        = $ this
			options      = $this.find('option').filter (n, e)->
				elem = $ e
				elem.val() || elem.text() == '-'
			activeOption = $this.find 'option:selected'
			$button      = $("<button/>").addClass('btn btn-default')

			$div.append($button.text(activeOption.text() + ' ').addClass('dropdown-toggle').attr('data-toggle', 'dropdown').append('<i class="fa fa-caret-down"/>'))

			options.each ->
				$self = $ this
				text  = $self.text()
				$li   = $ '<li/>'

				if text
					$a    = $('<a/>').attr('href', '#').on 'click', (e)->
						do e.preventDefault

						index = $(this).parent().index()

						$button.text(options.prop('selected', false).eq(index).prop('selected', true).text() + ' ').append('<i class="fa fa-caret-down"/>')
						$this.trigger 'change'



					if text == '-'
						text = ''

						$li.addClass 'divider'
						$a.detach()


					$ul.append $li.append $a.text text

			$div.append($ul.dropdown()).insertAfter($this)

	Select