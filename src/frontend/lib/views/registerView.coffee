define ['backbone', 'jquery', 'cookie', 'models/Person'], (backbone, $, cookie, Person)->
	class RegisterView extends backbone.View
		tpl: App.templates.register
		tagName: 'div'

		events: ->
			'submit form': 'send'

		send: (e)->
			do e.preventDefault
			person = new Person @$el.find('form').serializeObject()
			
			saveResult = person.save()
			
			unless saveResult
				Error person.validationError
			
			
			
		Error = (text)->
			err = $ '#error'
			
			if text
				err.html(App.templates.error(data: text: text))
				
				err.find('.alert').fadeIn(200)
				return true
				
			return false
		


		initialize: ->
			$('body').html @render()

		render: ->
			@$el.html do @tpl

			@$el

	RegisterView