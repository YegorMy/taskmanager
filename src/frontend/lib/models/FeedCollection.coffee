define ['backbone', 'models/FeedModel'], (Backbone, Model)->

	class FeedCollection extends Backbone.Collection
		model: Model
		url: '/api/feed/'

		initialize: (params)->
			if params
				if params.user
					this.url += "#{params.user}"
	FeedCollection