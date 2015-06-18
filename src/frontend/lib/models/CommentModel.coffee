define ['backbone'], (Backbone)->
	class CommentModel extends Backbone.Model
		defaults:
			text: ''
			user_id: ''
			created_date: ''
			task_id: ''
			files: []

		urlRoot: '/api/comment/'

	CommentModel