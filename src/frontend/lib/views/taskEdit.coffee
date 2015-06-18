define ['backbone', 'core/baseView', 'underscore', 'plugins/multiselect', 'plugins/select', 'plugins/datepicker', 'async'], (backbone, BaseView, _, multiselect, select, datepicker, async)->
	class TaskSingleView extends BaseView
		tpl:        App.templates.taskEdit
		model     = {}
		_id       = null
		dModel    = null
		superTask = null
		vent      = null

		events:
			'submit form': 'send'
			'click .file_delete': 'deletefile'

			'click .cancel': ->
				App.router.navigate '/', trigger: true
			'change #files': 'fileUpload'

		initialize: (m, id)->
			super

			model    = m
			search   = Backbone.history.location.search.replace('?', '').split('&')
			s        = {}
			vent     = _.extend {}, Backbone.Events

			for _s in search
				e = _s.split('=')

				s[e[0]] = e[1]

			if s.supertask
				superTask = s.supertask.toString()
				tModel    = new model id: s.supertask.toString()

				tModel.fetch success: (m)=>
					@renderSupertask m.toJSON()

			initPlugins = ->
				do select
				do multiselect


			vent.bind 'fetch', @renderAddUsers.bind @


			unless id
				do @render
				do datepicker

			if id
				console.log id
				_id = id
				dModel = new model id: id

				dModel.bind 'change', (m)=>
					@render m
					do datepicker

				return dModel.fetch success: =>
					@getUsers success: ->
						do initPlugins

			@getUsers success:->
				do initPlugins


		getUsers: (params)=>
			$.ajax
				url: '/api/user/getTaskCreators/'
				data: task: if superTask then superTask else _id
				type: 'GET'
				success: (response)=>
					vent.trigger 'fetch', response

					if params.success and typeof params.success == 'function'
						params.success response

		render: (data)->
			super

			d = {}

			if data
				d = data: data.toJSON()

			@$el.html @tpl App.assignData d

			$(@region).html @$el

		renderAddUsers: (data)->
			$performers  = ''
			$responsible = ''

			for user in data.responsibles
				user.name   = user._name
				user.id     = user._id

				if user.id == App.user.id
					user.name = 'Я'

				if dModel
					if dModel.get('responsible_id')._id == user.id
						user.selected = true

				tpl = App.templates.userElement user: user

				if user.id == App.user.id
					if data.responsibles.length > 1
						$responsible = '<option>-<option/>' + $responsible

					$responsible = tpl + $responsible

				else
					$responsible += tpl

			for user in data.performers

				if user.id == App.user.id
					user.name = 'Я'

				else
					user.name   = user._name

				if dModel

					if user.id == App.user.id
						user.name = 'Я'

					if user.id in dModel.get '_performer_ids'
						user.selected = true
					else
						user.selected = false

				$performers += App.templates.userElement user: user

			document.getElementById('userMultiSelect').innerHTML = $performers
			document.getElementById('responsible').innerHTML     = $responsible


		renderSupertask: (data)->
			html = App.templates.form_group(data: label: 'Подазача для', text: "<a href='/task/#{data._id}' target='_blank'>#{data.title}</a>") + App.templates.input input: type: 'hidden', name: 'parent_task_id', value: data._id
			el   = document.getElementById 'subtask_for'


			if el
				el.innerHTML = html

		fileUpload: (e)->
			files = e.target.files
			fd    = new FormData()


			for file, i in files
				fd.append "file#{i}", file

			$.ajax
				url: '/api/files/'
				data: fd
				cache: false
				processData: false
				contentType: false
				type: 'POST'
				success: @renderFiles.bind @

		renderFiles: (files)->
			inputs   = document.getElementById('task_file_containers')
			inputTpl = App.templates.input
			fileTpl  = App.templates.fileElement
			_new     = false
			html     = ''
			fileHtml = ''
			fileLen  = inputs.children.length / 2

			unless inputs
				inputs    = document.createElement('div')
				inputs.id = 'task_file_containers'
				_new      = true

			for file, i in files
				html += inputTpl input: name: "files[#{i + fileLen}][0]", value: file.originalname, type: 'hidden'
				html += inputTpl input: name: "files[#{i + fileLen}][1]", value: file.name, type: 'hidden'

				fileHtml += fileTpl file: file

			if _new
				@el.getElementsByTagName('form')[0].appendChild inputs

			files            = document.getElementById 'files_container'
			files.innerHTML  += fileHtml
			inputs.innerHTML += html
			html             = null

		deletefile: (e)->
			do e.preventDefault

			fileElement = e.target.parentNode.parentNode
			nodeList    = Array::slice.call @el.getElementsByClassName 'file'
			index       = nodeList.indexOf fileElement
			nodeList    = null

			if index > -1
				children = task_file_containers.children

				children[index * 2].value = ''
				children[index * 2 + 1].value = ''

				fileElement.style.display = 'none'


		send: (e)->
			do e.preventDefault

			s               = @serialize @$el.find 'form'
			s.performer_ids = @$el.find('form').find('select.multi').val() # la kostilleh
			files           = []
			keys            = Object.keys s

			for k in keys
				matchResult = k.match /files\[([0-9]+)\]\[([0-9]+)\]/i

				if matchResult

					if matchResult[1] and matchResult[2]

						unless files[matchResult[1]]
							files[matchResult[1]] = []

						files[matchResult[1]][matchResult[2]] = s[k]

			s.files = files
			files   = null

			if _id
				s.id = _id

			if !s.title or !s.text or !s.date_to
				err = 'Поля "Заголовок", "Текст" и "Дата" обязательны для заполнения'

			@$el.find('.alert-danger').remove()

			if err
				return $(App.templates.error data: text: err).fadeIn(200).appendTo $ 'form'

			s.created_id = App.user.id
			m            = new model s

			m.save {}, success: ->
				App.router.navigate '', trigger: true


		_destroy: ->
			dModel = null
			model  = null

			vent.off 'fetch'

			vent   = null

	TaskSingleView