define ['jquery', 'core/baseView', 'plugins/select', 'underscore', 'plugins/multiselect'], ($, BaseView, select, _, multiselect)->
	class LKView extends BaseView
		tpl: App.templates.lk

		events:
			'submit #main': 'submit'
			'submit #task_creators': 'saveTaskCreators'
			'change #avatar': 'uploadAvatar'

		vent         = _.extend {}, Backbone.Events
		userModel    = null
		taskCreators = []

		initialize: (c)->
			super

			collection = new c


			vent.bind 'fetch', =>
				collection.fetch success: @taskCreators.bind @

			collection.bind 'add', @renderAddUser.bind @

			vent.trigger 'fetch'

			@render App.user
			do select

		uploadAvatar: (e)->
			avatar = @$el.find('#avatar_photo')

			$.ajax
				url: '/api/files/avatar/'
				data: new FormData($('#main')[0])
				cache: false
				processData: false
				contentType: false
				type: 'POST'
				success: (path)->
					avatar.attr('src', path.file)
					console.log path.file
					#App.user.avatar = path.file


		render: (data = null)=>
			super

			d = {}

			if data
				d = data: data

			@$el.html @tpl d

			$(@region).html @$el

		error: (text)->
			$('.error').remove()
			@$el.append $(App.templates.error data: text:text).fadeIn(200)

		success: (text = "Данные обновлены")->
			$('.alert.success').remove()
			@$el.append $(App.templates.success data: text:text).fadeIn(200)

		taskCreators: ->
			t = @$el.find '#taskCreators'

			if taskCreators.length
				for creator in taskCreators
					t.find("[value=#{creator}]").prop('selected', true)

			do multiselect

		renderAddUser: (m)->
			modelToJSON = m.toJSON()
			modelToJSON.name = modelToJSON._name

			if m.get('_id') == App.user.id
				taskCreators = m.get 'task_creators'
			else

				modelToJSON.id = modelToJSON._id
				@$el.find('#taskCreators').append $ App.templates.userElement user: modelToJSON

		saveTaskCreators: (e)->
			do e.preventDefault

			$.ajax
				url: '/api/user/setTaskCreators/'
				type: 'POST'
				dataType: 'JSON'
				data: task_creators: @$el.find('#taskCreators').val()
				success: =>
					do @success

		submit: (e)->
			do e.preventDefault

			data = @serialize @$el.find 'form'

			if data.pass and data.passAgain
				if data.pass != data.passAgain
					return @error 'Пароли должны совпадать'


			if !data.name or !data.surname or !data.login or !data.email or !data.status
				return @error 'Все поля обязательны для заполнения'

			$.ajax
				url: '/api/user/' + App.user.id
				data: data
				dataType: 'JSON'
				type: 'PUT'
				success: (response)=>
					App.user = _.extend App.user, data
					console.log _.extend App.user, data
					if response.success
						do @success

		_destroy: ->
			vent.off 'fetch'
			@user = null

	LKView
