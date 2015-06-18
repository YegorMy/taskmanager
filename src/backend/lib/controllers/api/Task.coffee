FeedWriter = require '../abstract/FeedWriter'
oID        = require('mongoose').Types.ObjectId

class Task extends FeedWriter
	model = Models.Task
	constructor: (app)->
		super

		@addPath 'task/'

		@init app

	init: (app)=>
		path = do @getPath

		app.get "#{path}", @_get 'open'
		app.get "#{path}closed/", @_get 'closed'
		app.get "#{path}projects/", @_get 'projects'
		app.get "#{path}sub/:id", @getSubtasks

		app.get "#{path}user/:id", @getByUser
		app.get "#{path}:id", @get

		app.put "#{path}:id", @update

		app.post "#{path}", @create
		app.post "#{path}close/:id", @close
		app.post "#{path}setReadiness/:id", @setReadiness
		app.post "#{path}decline/:id", @decline

		app.delete "#{path}:id", @remove


	_get: (mode)=>
		return (req, res, next)=>
			@getAll req, res, next, mode

	getSubtasks: (req, res)->
		async = require 'async'

		async.waterfall [
			(callback)->
				model.findById(req.params.id).populate('created_id responsible_id performer_ids').exec callback
			(task, callback)->
				unless task
					do callback

				model.find(parent: task._id).populate('created_id responsible_id performer_ids').exec (err, tasks)->
					t = task.toObject()
					t.subtasks = tasks

					callback err, t
		], (err, task)->
			res.json task


	getAll: (req, res, next, mode)->
		user   = req.user
		async  = require 'async'
		$or    = [{created_id: $ne: null}]
		params =
			responsible_id: $ne: null
			closed_date: null


		if user
			$or = [
				{created_id: user}
				{responsible_id: user}
				{performer_ids: user}
			]

		unless req.query.nofilter
			if mode == 'closed'
				params.closed_date = $ne: null
			else if mode == 'projects'
				params.parent_task_id = null
				$or = [{_id: $ne: null}]
			else if mode != 'projects'
				params.parent_task_id = $ne: null

		async.waterfall [
			(callback)->
				model.find(params).or($or).populate('responsible_id parent_task_id project').exec (err, tasks)->
					throw new Error err if err

					t = []

					for k in tasks
						k = k.toObject()

						k.id = k._id

						k = createDates k

						t.push k

					callback null, t

			(tasks, callback)->
				newTasks = []
				async.each tasks, ((task, callback)->
					if task
						return async.parallel [
							(callback)->
								Models.Comment.count task_id: task._id, callback
							(callback)->
								Models.Task.count parent_task_id: task._id, callback
							(callback)->
								Models.User.getOne _id: task.created_id, callback

						], (err, result)->
							[task.comments, task.subtasks, user] = result

							if user
								task.created_name = user.name

							newTasks.push task

							do callback

					do callback
				), ->
					callback null, newTasks.sort (a, b)->
						if a.created_date > b.created_date
							return -1
						return 1

		], (err, tasks)->
			res.json tasks

	get: (req, res)->
		async  = require 'async'
		id     = req.params.id
		moment = require 'moment'
		moment.locale('ru')
		moment()

		unless oID.isValid(id) and id
			return res.json error: "ID #{id} is not valid"

		async.parallel [
			(callback)->
				model.findById(id).populate('performer_ids created_id responsible_id parent_task_id project').exec (err, task)->
					t = null

					if task
						t = task.toObject()
						k = 0
						if t.performer_ids
							k = t.performer_ids.length
						u = []

						t = createDates t

						while k
							k--
							u.push t.performer_ids[k]._id

						t._performer_ids = u

					callback null, t

			(callback)->
				model.find(parent_task_id:id).populate('performer_ids created_id responsible_id').exec callback
		], (err, result)->
			throw new Error err if err
			task = {}

			if result[0]
				[task, task.subtasks] = result
			else
				task = null

			res.json task

	getByUser: (req, res)->

		user  = req.params.id
		$or   = [{created_id: user}, {responsible_id: user}, {performer_ids: user}]
		async = require 'async'

		unless oID.isValid(user) and user
			return res.json error: "ID #{user} is not valid"

		unless user
			return res.json error: 'user must be'

		Models.Task.find().or($or).populate('created_id responsible_id performer_ids project').exec (err, tasks)->
			_tasks = []

			async.parallel [
				(callback)->
					async.each tasks, ((e, callback)->
						task       = e.toObject()
						task._name = e.get '_name'
						id         = e._id

						task = createDates task

						async.parallel [

							(callback)->
								Models.Task.count parent_task_id: id, callback
							(callback)->
								Models.Comment.count task_id: id, callback
						], (err, result)->
							[task.subtasks, task.comments] = result

							_tasks.push task

							do callback
					), (err)->
						callback err, _tasks.sort (a, b)->

							if a > b
								return -1

							return 1
				(callback)->
					Models.User.byID req.params.id, callback

			], (err, result)->
				res.json tasks: result[0], user: result[1]


	create: (req, res)=>
		body    = req.body
		async   = require 'async'
		feed    = []
		toFeed  = @toFeed
		Write   = @writeToFeed

		body    = prepareTask body, req.user

		unless body
			return res.json error: 'Поля "Текст", "Заголовок" и "Дата" обязательны для заполнения'

		async.waterfall [
			(callback)->
				unless body.parent_task_id
					return do callback

				unless oID body.parent_task_id
					return callback true


				Models.Task.findById body.parent_task_id, (err, parentTask)->
					if parentTask
						if parentTask.project
							body.project = parentTask.project
						else
							body.project = parentTask._id

					callback err, parentTask

			(parentTask, callback)->
				if parentTask && callback
					return Models.Task.find($or: [{project: body.project}, {_id: body.project}]).sort('created_date': 'desc').exec (err, tasks)->
						toFeed tasks, 'add_subtask', req.user, body.project, callback

				do parentTask

			(callback)->
				model.create body, callback

			(task, callback)->
				mongoose = require 'mongoose'
				feed     = []

				unless body.performer_ids
					return do callback

				for e in body.performer_ids
					feed.push id: e, type: 'add_performer'

				if body.responsible_id
					feed.push id: body.responsible_id, type: 'add_responsible'

				async.each feed, ((e, callback)->
					Write e, req.user, task.id, callback
				), ->
					do callback

		], (err)->
			if err
				return res.json err: err

			res.json success: true

	update: (req, res)=>
		Models.User.getOne token: req.cookies.user, (err, user)=>
			unless user
				res.json error: 'User must be specified!'

			user          = user._id
			body          = prepareTask req.body, user
			async         = require 'async'
			prepareToFeed = @prepareToFeed
			Write         = @writeToFeed

			unless body
				return res.json error: 'Поля "Текст", "Заголовок" и "Дата" обязательны для заполнения'

			unless oID.isValid(req.params.id) and req.params.id
				return res.json error: "ID #{req.params.id} is not valid"

			unless req.params.id
				return res.json error: 'ID must be specified'

			model.findById req.params.id, (err, model)->
				if model.is_declined or model.is_declined or model.closed_date
					return res.json error: 'Task can not be modified'

				if !/[0-9abcdef]/i.test body.parent_task_id
					body.parent_task_id = null

				project = model.project
				feed    = []

				unless project
					project = model._id

				async.parallel [
					(callback)->
						Models.Task.find().or([{project: project}, {_id: model._id}]).exec (err, tasks)->
							for id in prepareToFeed tasks
								feed.push id: id, type: 'edit_task'

							_performers = model.get('performer_ids') || []
							performers  = body.performer_ids

							createdID   = model.get('created_id').toString()

							if body.performer_ids
								for e in _performers

									if !~body.performer_ids.indexOf e.toString()
										feed.push id: e, type: 'remove_performer'

								for e in performers

									if !~_performers.indexOf e
										feed.push id: e, type: 'add_performer'

							r1 = body.responsible_id
							r2 = model.get('responsible_id').toString()

							if r1 != r2

								if createdID != r1
									feed.push id: r1, type: 'add_responsible'

								if createdID != r2
									feed.push id: r2, type: 'remove_responsible'

							async.each feed, ((e, callback)->
								Write e, user, model._id, callback
							), callback
				], (err)->
					console.log feed
					throw new Error err if err

					model.set body
					model.save()

					res.json success: true

	remove: (req, res)->
		model.remove _id: req.params.id, (err, removed)->
			throw new Error err if err

			res.json {success: true}


	close: (req, res)->

		model.findById req.params.id, (err, task)->
			throw new Error err if err

			task.set 'closed_date', new Date()
			task.set 'task_status_id', 'Закрыта'
			task.set 'readiness', 0

			do task.save

			res.json success: true

	decline: (req, res)=>
		user   = req.params.id
		toFeed = @toFeed

		model.findById user, (err, task)->
			if task.created_id.toString() == user || task.responsible_id.toString() == user
				return res.json error: 'You can not decline this task'



			toFeed [task], 'declined', req.user, task, ->
				task.set 'is_declined': true, 'closed_date': new Date, 'status': 'Отменена', readiness: 0

				task.save()
				res.json {ok:true}

	setReadiness: (req, res)=>
		async  = require 'async'
		user   = req.user
		toFeed = @toFeed

		unless oID.isValid(req.params.id) and req.params.id
			return res.json error: "ID #{req.params.id} is not valid"

		async.parallel [

			(callback)->
				model.findById req.params.id, (err, task)->
					readiness = parseInt req.body.readiness

					if isNaN readiness
						return callback true

					callback null, readiness, task

			(callback)->
				model.count parent_task_id: req.params.id, callback
		], (err, result)->

			if err
				return res.json error: 1

			readiness = parseInt result[0][0]
			task      = result[0][1]
			count     = result[1]

			if task.is_declined or task.is_declined or task.closed_date or ((task.performer_ids.map (e)-> e.toString()).indexOf(user) == -1 and user != task.responsible_id.toString() and user != task.created_id.toString())
				return res.json error: 'Task can not be modified'

			if count < 1
				set  =
					readiness: readiness
				type = 'status_change'


				if readiness == 100
					set.is_completed = true
					set.closed_date  = new Date
					set.status       = 'Выполнена'

					type             = 'competed'


				return async.parallel [
					(callback)->
						task.set set
						task.save ->
							do callback

					(callback)->
						toFeed [task], type, req.user, task, callback, readiness
				], ->
					res.json ok: true


			res.json error: 'Readiness can not be changed'



	renderFiles = (files)->
		f = []
		if files
			if files.length
				for file, num in files
					f[num] = name: file[1], originalname: file[0]

		f

	createDates = (t)->
		moment             = require 'moment'
		moment.locale('ru')

		date_to            = t.date_to
		created_date       = t.created_date

		momentDate_to      = moment(date_to)
		momentCreated_date = moment(created_date)

		add                = momentDate_to.from(new Date())

		if momentDate_to.isBetween(moment(), moment().add(1, 'days'))
			add = 'завтра'

		t.date_to_print      = add + ' (' + momentDate_to.format('D MMMM YYYY [года в] HH:mm') + ')'
		t.date_to_edit       = momentDate_to.format('D MM YYYY HH:mm')
		t.created_date_print = momentCreated_date.format('D MMMM YYYY [года в] HH:mm')
		t.date_to            = momentDate_to.format('D MMMM YYYY HH:mm')
		t.created_date       = momentCreated_date.format('D MMMM YYYY HH:mm')
		if t.closed_date
			t.closed_date    = moment(t.closed_date).format('D MMMM YYYY [года в] HH:mm')

		if new Date(date_to) < new Date()
			t.prosrana = true

		t

	prepareTask = (body, user)->
		body.date_to = stringToDate body.date_to
		body.files   = renderFiles body.files

		if !/[0-9abcdef]/i.test body.parent_task_id
			body.parent_task_id = null

		if !body.performer_ids
			body.performer_ids = []

		if !body.responsible_id
			body.responsible_id = user

		if !body.created_id
			body.created_id = user

		if !body.text or !body.title or !body.date_to
			return null

		body

	stringToDate = (string)->
		d     = string.split ' '
		days  = d[0].split '.'
		hours = d[1].split ':'

		return new Date days[2].replace(/$0/, ''), parseInt(days[1].replace(/$0/, '')) - 1, parseInt(d[0]), hours[0], hours[1]

	dateToString = (d)->
		date = new Date d

		return addZero(date.getDate()) + '.' + addZero(date.getMonth() + 1) + '.' + date.getFullYear() + ' ' + addZero(date.getHours()) + ':' + addZero(date.getMinutes())

	addZero = (n)->
			return if n > 9 then n else '0' + n

module.exports = (app, callback)->
	Logger.info 'Task controller required'
	new Task app
	do callback