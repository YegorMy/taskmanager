API = require './API'
oID = require('mongoose').Types.ObjectId

class Feed extends API
	model = Models.Feed

	constructor: (app)->
		super

		@addPath 'feed/'

		@initialize(app)

	initialize: (app)=>
		path = do @getPath

		app.get "#{path}", @get

	get: (req, res)->
		model.find(for: req.user).populate('task_id').exec (err, feed)->
			feeds = []
			async = require 'async'

			async.each feed, ((e, callback)->
				f = e.toObject()

				Models.User.byID e.user_id, (err, user)->
					f.user_id = user
					feeds.push f

					do callback
			), ->

				res.json feeds.filter((e)->
					!!e.task_id
				).sort (a, b)->
					if a.created_date > b.created_date
						return -1

					return 1

module.exports = (app, callback)->
	Logger.info 'Feed controller required'
	new Feed app
	do callback