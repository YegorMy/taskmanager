define ['backbone'], (Backbone)->
	class TaskModel extends Backbone.Model
		defaults:
			title: ''
			text: ''
			created_id: ''
			closed_date: ''
			performer_ids: []
			responsible_id: ''
			tasks: []

		urlRoot: '/api/task/'

	TaskModel