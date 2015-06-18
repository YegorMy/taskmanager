define ['backbone', 'jquery', 'cookie'], (backbone, $, cookie)->
	class LoginView extends backbone.View
		tpl: App.templates.login
		tagName: 'div'
		errors: []

		events:
			'submit form': 'send'

		initialize: ->
			do @render

		render: ->
			$('body').html @$el.html do @tpl

		doError: (err)=>
			$('.alert-danger').remove()
			@$el.find('form').append $(App.templates.error data:text:err).fadeIn(200)

		send: (e)->
			do e.preventDefault

			data    = do @$el.find('form').serializeObject
			errTxt  = ''
			doError = @doError

			if !data.login or !data.passwd
				errTxt = 'Поля "Логин" и "Пароль" обязательны для заполнения'

			if errTxt
				doError errTxt
				return

			$.ajax
				url: '/api/user/login/'
				type: 'post'
				dataType: 'JSON'
				data: data
				success: (response)->
					if response.error
						return doError response.error

					if response.success
						cookie.set 'user', response.token, 
						cookie.set 'login', response.id

						App.router.navigate '/', {trigger: true}

	LoginView