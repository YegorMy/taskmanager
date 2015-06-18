define ['backbone'], (Backbone)->
	class FeedModel extends Backbone.Model
		defaults:
			for: ''
			user_id: ''
			created_date: ''
			task_id: ''
			feed_type: ''

		urlRoot: '/api/feed/'

	FeedModel