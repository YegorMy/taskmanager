define ['jquery', 'core/baseView', 'plugins/select', 'underscore'], ($, BaseView, select, _)->
	class TaskView extends BaseView

		tpl:      App.templates.taskView
		model:    {}
		_id     = null
		vent    = null

		events:
			'click .delete':        'delete'
			'change #status':       'changeStatus'
			'click #sendComment':   'sendComment'
			'click #close':         'closeTask'
			'mousemove #readiness': 'changeReadinessTooltip'
			'click #decline':       'decline'
			'click #attachFiles':   'attach'
			'change #file_emitter': 'load_files'
			'click .file_delete':   'file_delete'

			'mouseout #readiness':  ->
				document.getElementById('tooltip').style.display = 'none'

			'click #readiness':     'changeReadiness'

		initialize: (model, id)->
			super

			vent    = _.extend {}, Backbone.Events
			@model  = new model id: id
			_id     = id

			vent.bind 'fetch', =>
				@model.fetch()

			@model.bind 'change', @render.bind @
			vent.trigger 'fetch'

			do @getComments

		attach: (e)->
			do e.preventDefault

			elem = document.getElementById('file_emitter')

			if elem
				evt  = new Event('click')

				elem.dispatchEvent(evt)

		load_files: (e)->
			files = e.target.files
			fd    = new FormData

			for file, i in files
				fd.append "file#{i}", file

			xhr = new XMLHttpRequest()
			xhr.contentType = false
			xhr.processData = false
			xhr.cache       = false
			xhr.open 'POST', '/api/files/'

			xhr.send fd

			xhr.onreadystatechange = ->
				if xhr.readyState == 4
					if xhr.status == 200

						files       = JSON.parse(xhr.responseText)
						html        = ''
						tpl         = App.templates.fileElement
						files_input = ''
						inputTPL    = App.templates.input

						for file, i in files
							files_input += inputTPL input: type: 'hidden', name: "files[#{i}][0]", value: file.originalname, classname: 'comment_files_input'
							files_input += inputTPL input: type: 'hidden', name: "files[#{i}][1]", value: file.name, classname: 'comment_files_input'

							html += tpl file: file

						comment_files = document.getElementById('comment_files')

						if comment_files
							comment_files.innerHTML = html + files_input

		file_delete: (e)->
			do e.preventDefault

			fileElement = e.target.parentNode.parentNode
			nodeList    = Array::slice.call @el.getElementsByClassName 'file'
			index       = nodeList.indexOf fileElement
			nodeList    = null

			if index > -1
				children = document.getElementById('comment_files').getElementsByClassName('comment_files_input')

				children[index * 2].value = ''
				children[index * 2 + 1].value = ''

				fileElement.style.display = 'none'



		render: (data = null)->
			super

			if !data
				data = {}
			else
				data = data.toJSON()

			@$el.html @tpl App.assignData data: data

			$(@region).html @$el

			do select

		changeReadiness: (e)->
			if (@model.get('responsible_id').toString() == App.user.id or App.user.id in @model.get('_performer_ids') or App.user.id == @model.get('created_id')._id.toString()) and @model.get('subtasks').length == 0
				percentage = calculatePercentage e
				$target    = getTarget e.target
				bar        = $($target).find '.progress-bar'

				bar.text(percentage + '%').css('width', percentage + '%')

				$.ajax
					url: '/api/task/setReadiness/' + _id
					dataType: 'JSON'
					type: 'POST'
					data: readiness: percentage


		changeReadinessTooltip: (e)->
			if (@model.get('responsible_id').toString() == App.user.id or App.user.id in @model.get('_performer_ids') or App.user.id == @model.get('created_id')._id.toString()) and @model.get('subtasks').length == 0

				percentage    = calculatePercentage(e) + '%'
				$target       = getTarget e.target
				tooltip       = document.getElementById('tooltip')
				style         = tooltip.style
				style.left    = (e.clientX - $target.offset().left) + 'px'
				style.opacity = 1
				style.display = 'block'

				tooltip.getElementsByClassName('tooltip-inner')[0].innerHTML = percentage

		getComments: ->
			$.ajax
				url: '/api/comment/' + _id
				type: 'GET'
				success: @renderComments

		renderComments: (comments)->
			k          = -1
			commentsEl = $ '<div/>'
			commentTpl = App.templates.commentElement

			while k < comments.length - 1
				e                  = comments[++k]
				e.formatedDateTime = App.format e.created_date

				commentsEl.append $ commentTpl data:e

			$('#comments').empty().append commentsEl


		sendComment: (e)->
			do e.preventDefault

			textarea = @el.getElementsByTagName('textarea')[0]
			text     = textarea.value
			if text == ''
				return


			console.log text
			#fileInps = @el.getElementsByClassName('comment_files_input')
			#data     = []
			###
			for input in fileInps
				matchResult = input.name.match /files\[([0-9]+)\]\[([0-9]+)\]/i

				if matchResult

					if matchResult[1] and matchResult[2]

						unless data[matchResult[1]]
							data[matchResult[1]] = []

						data[matchResult[1]][matchResult[2]] = input.value###

			textarea.value = ''
			#document.getElementById('comment_files').innerHTML = ''

			fd  = new FormData()

			#fd.append 'files', data
			fd.append 'text', text

			xhr = new XMLHttpRequest()

			xhr.open "POST", '/api/comment/' + _id
			xhr.send fd

			xhr.onreadystatechange = =>
				if xhr.readyState == 4
					if xhr.status == 200
						do @getComments

		closeTask: (e)->
			do e.preventDefault


			$.ajax
				url:'/api/task/close/' + _id
				type: 'POST'
				success: (response)=>
					@$el.prepend $(App.templates.success data: text: 'Задача закрыта').fadeIn(200)

		decline: (e)->
			do e.preventDefault
			userID = App.user.id

			if userID == @model.get('created_id')._id.toString() or userID == @model.get('responsible_id')._id.toString()
				$.ajax
					url: '/api/task/decline/' + @model.get('_id')
					type: 'POST'
					dataType: 'JSON'
					success: =>
						vent.trigger 'fetch'

		_destroy: ->
			@model.off 'change'
			@model = null

			vent.off 'fetch'
			vent = null

		calculatePercentage = (e)->
			$target    = getTarget e.target

			offset     = $target.offset()
			x          = Math.round e.clientX - offset.left

			return Math.ceil((x / $target.width()) * 100)

		getTarget = (target)->
			$target = $ target

			unless $target.attr('id')
				$target = $target.parent()

			$target

	TaskView