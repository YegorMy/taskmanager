API = require './API'

class User extends API
	model = Models.User

	constructor: (app)->
		super

		@addPath 'user/'

		@init app

	init: (app)=>
		path = do @getPath

		app.post "#{path}", @register
		app.post "#{path}login/", @login
		app.post "#{path}setTaskCreators/", @setTaskCreators

		app.get "#{path}", @get
		app.get "#{path}getTaskCreators/", @getTaskCreators
		app.get "#{path}:token", @getByToken

		app.put "#{path}:id", @update

	register: (req, res)->
		body = req.body

		# Переписать логику, вынеся проверки в модель.
		model.create body, (err, user)->
			throw new Error err if err

			res.json success: true, token: token

	login: (req, res)->
		body   = req.body
		error  = ''

		if body.login && body.passwd
			model.findOne {login: body.login}, (err, user)->
				error = 'Такой пары логин/пароль не найдено'

				if user
					if user.comparePassword body.passwd
						error = null

				if error
					return res.json error: error

				token = user.token
				unless token
					token = do generateToken
					user.set 'token', token
					do user.save
				res.cookie('login', user.id);
				res.cookie('user', String(token));
				res.json success: true, token: token, id: user.id

		else
			res.json error: 'fields are required'


	get: (req, res)->
		async = require 'async'

		async.waterfall [

			(callback)->
				model.find name: '$ne': null, callback

			(users, callback)->
				nUsers = []

				async.each users, ((user, callback)->
					us  = user.toObject()
					us._name = user.get '_name'

					if req.query.task_creators == 'true' and req.user not in us.task_creators
						return do callback

					$or = [{created_id: user._id}, {responsible_id: user._id}, {performer_ids: user._id}]

					async.parallel [
						(callback)->
							Models.Task.count(closed_date: null).or($or).exec callback
						(callback)->
							Models.Task.count(closed_date: $ne: null).or($or).exec callback
					], (err, res)->
						us.open_task   = res[0]
						us.closed_task = res[1]

						nUsers.push us

						do callback
				), ->
					callback null, nUsers

		], (err, users)->
			throw new Error err if err

			res.json users

	getTaskCreators: (req, res)->
		async        = require 'async'
		isCreator    = isResponsible = isPerformer = false
		user         = req.user
		taskID       = req.query.task

		async.waterfall [
			(callback)->
				async.parallel [
					(callback)->
						unless taskID
							return callback null, []

						Models.Task.findById taskID, (err, task)->
							t = null

							if task
								t                = task.toObject()
								t.performer_ids  = t.performer_ids.map (e)-> e.toString()
								t.responsible_id = t.responsible_id.toString()

								unless task
									do callback

								if task.created_id.toString() == user
									isCreator = true
								if task.responsible_id.toString() == user
									isResponsible = true
								if user in task.performer_ids.map((e)-> e.toString())
									isPerformer = true

							callback err, t
					(callback)->
						Models.User._get task_creators: user, (err, users)->
							callback err, users.map (e)-> e._id.toString()
				], callback
			(result, callback)->
				performers   = [user]
				responsibles = [user]

				if !taskID or isCreator
					responsibles = responsibles.concat result[1]
					performers = performers.concat result[1]

				[task, usersToTask] = result

				if isPerformer
					performers = performers.concat usersToTask

				if isResponsible
					responsibles = responsibles.concat usersToTask.concat [task.responsible_id] # Госпади.
					performers   = performers.concat usersToTask.concat task.performer_ids


				responsibles = responsibles.filter unique
				performers = performers.filter unique

				callback null, responsibles, performers

			(responsobles, performers, callback)->
				queried = []
				all     = responsobles.concat performers
				_p      = []
				_r      = []

				async.each all, ((e, callback)->

					if e in queried
						return do callback

					queried.push e

					Models.User.byID e, (err, user)->
						if e in responsobles
							_r.push user

						if e in performers
							_p.push user

						do callback
				), ->
					callback null, responsibles: _r, performers: _p


		], (err, data)->
			if err
				return res.json error: 'Something went wrong'

			res.json data

	setTaskCreators: (req, res)->
		Models.User.findById req.user, (err, user)->
			throw new Error err if err

			task_creators = req.body.task_creators

			unless task_creators
				task_creators = []

			user.set 'task_creators', task_creators
			user.save()

			res.json success: true

	getByToken: (req, res)->
		token = req.params.token

		if token
			return model.getOne token: req.params.token, (err, user)->
				console.log user
				if user
					u =
						id: user._id
						name: user.name
						surname: user.surname
						login: user.login
						email: user.email
						status: user.status
						avatar: user.avatar


					console.log u

					return res.json u

				res.json error: 1

		res.json error: 1

	update: (req, res)->
		model.findById req.params.id, (err, user)->
			throw new Error err if err

			console.log req.body

			user.set req.body

			do user.save

			res.send success: true

	generateToken = (l = 25)->
		alphabet = 'abcdefghijklmnopqrstuvwxyz'.split ''
		i        = l
		token = ''
		while i > 0
			token += alphabet[Math.round(Math.random() * 25)]
			i--

		token

	unique = (e, index, ar)->
		return ar.indexOf(e) == index

module.exports = (app, callback)->
	Logger.info 'User controller required'
	new User app
	do callback
