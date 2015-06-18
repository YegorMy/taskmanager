define ['core/baseView'], (BaseView)->
	class View extends BaseView
		tpl:        App.templates.userSingleElement
		collection: null

		initialize: (id)->
			super

			$.ajax
				url: "/api/task/user/#{id}"
				type: 'GET'
				dataType: 'JSON'
				success: (response)=>
					@render response

		addTasks: (tasks)->
			tpl = App.templates.singleTask
			div = ''

			for task in tasks
				div += tpl task: task

			document.getElementById('userTasks').innerHTML = div

		render: (data = null)->
			super

			@el.innerHTML = @tpl user: data.user.name + ' ' + data.user.surname

			document.getElementById(@region.replace '#', '').innerHTML = @el.innerHTML

			@addTasks data.tasks

	View