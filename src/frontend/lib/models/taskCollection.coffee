define ['backbone', 'models/taskModel'], (Backbone, Model)->
	class TaskCollection extends Backbone.Collection
		model: Model
		url: '/api/task/'

		initialize: (params)->
			get = []

			if params
				if params.url
					this.url = params.url

				if params.user
					get.push "user=#{params.user}"

				if params.nofilter
					get.push "nofilter=#{params.nofilter}"

				this.url += '?' + get.join('&')


	TaskCollection