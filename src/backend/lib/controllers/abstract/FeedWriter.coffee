API = require '../api/API'

class FeedWriter extends API
	constructor: ->
		super

	prepareToFeed: (tasks)->
		async  = require 'async'
		ids    = []
		feed   = []

		for task in tasks
			perfs   = task.get('performer_ids').map (e)-> e.toString()
			respID  = task.get('responsible_id').toString()
			created = task.get('created_id').toString()

			for p in perfs when p not in ids
				ids.push p
				feed.push p

			if respID not in ids
				ids.push respID
				feed.push respID

			if created not in ids
				ids.push created
				feed.push created

		return feed

	toFeed: (tasks, feedType, user, project, callback, readiness = null)=>
		feed  = @prepareToFeed tasks
		async = require 'async'
		Write = @writeToFeed
		console.log feed

		async.each feed, ((id, callback)->

			Write {id: id, type: feedType}, user, project, callback, readiness

		), callback

	writeToFeed: (e, user, task_id, callback, readiness)->
		if !e.id or !e.type or !user or !task_id or !callback
			throw new Error 'e, user, task_id, callback are required!'

		d =
			for: e.id
			user_id: user
			task_id: task_id
			feed_type: e.type

		if readiness
			d.readiness = readiness

		Models.Feed.create d, callback

module.exports = FeedWriter