define ['backbone', 'models/CommentModel'], (Backbone, Model)->
	class CommentCollection extends Backbone.Collection
		model: Model
		url: '/api/comment/'

	CommentCollection