define ['jquery', 'core/baseView'], ($, BaseView)->
	class IndexView extends BaseView
		tpl: App.templates.index
		collection: {}

		initialize: (collection)->
			super

			mode = Backbone.history.location.pathname.split('/').reverse()[0] + '/'
			data = {}

			if mode != 'open/' and mode != 'closed/' and mode != 'projects/'
				mode = ''

			data.url = '/api/task/' + mode


			c = new collection data

			c.on 'add', @renderAdd
			c.on 'change remove', @render


			do c.fetch

			do @render

		render: (data = {})=>
			super

			@$el.html @tpl data

			$(@region).html @$el

		renderAdd: (data)=>
			@$el.append App.templates.singleTask task: data.toJSON()


	IndexView
