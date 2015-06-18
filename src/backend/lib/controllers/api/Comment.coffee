FeedWriter = require '../abstract/FeedWriter'
oID        = require('mongoose').Types.ObjectId

class Comment extends FeedWriter
	constructor: (app)->
		super

		@addPath 'comment/'

		@init app


	init: (app)=>
		path = do @getPath

		app.get "#{path}:id", @get

		app.post "#{path}:id", @add

	get: (req, res)->
		Models.Comment.find(task_id: req.params.id).populate('user_id').exec (err, comments)->
			throw new Error err if err

			res.json comments

	add: (req, res)=>
		body   = req.body
		async  = require 'async'
		taskID = req.params.id
		create = text: body.text, user_id: req.user, task_id: taskID
		toFeed = @toFeed

		unless oID.isValid req.params.id
			res.json error: "ID #{req.params.id} is not valid"

		if req.body.files

			_files = req.body.files.split ','
			files  = []

			i = _files.length

			while i
				files.push name: _files[--i], originalname: _files[--i]

			create.files = files

		async.parallel [
			(callback)->
				Models.Comment.create create, callback
			(callback)->
				Models.Task.findById taskID, (err, task)->
					ids    = []

					project = task.project

					unless project
						project = task._id

					Models.Task.find $or: [{project:project}, {_id: project}], (err, tasks)->
						throw new Error err if err

						toFeed tasks, 'add_comment', req.user, task, callback
		], ->
			res.json success: true


module.exports = (app, callback)->
	Logger.info 'Comment controller required'

	new Comment app
	do callback
