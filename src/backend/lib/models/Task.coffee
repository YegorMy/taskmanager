mongoose = require 'mongoose'
mongooseSchena = mongoose.Schema
oID = mongooseSchena.Types.ObjectId

schema = new mongooseSchena
	title: String
	text: String
	created_id:
		type: oID
		ref: 'User'
	created_date:
		type: Date
		default: Date.now
	closed_date:
		type: Date
		default: null
	status:
		type: String
		enum: ['Создана', 'Отменена', 'Выполнена']
		default: 'Создана'
	is_declined:
		type: Boolean
		default: false
	is_completed:
		type: Boolean
		default: false
	performer_ids:
		type: [{type:oID, ref: 'User'}]
		default: []
	project:
		type: oID
		ref: 'Task'
		default: null
	parent_task_id:
		type: oID
		ref: 'Task'
		default: null
	responsible_id:
		type: oID
		ref: 'User'
	readiness:
		type: Number
		default: 0
	date_to:
		type: Date
	files: [{name: String, originalname: String}]


model = mongoose.model 'Task', schema

model.schema.pre 'save', (next)->
	async     = require 'async'

	if @parent_task_id
		m         = @
		readiness = m.readiness

		return async.waterfall [
			(callback)->
				model.find parent_task_id: m.parent_task_id, is_declined: false, _id: $ne: m._id, callback
			(tasks, callback)=>
				for task in tasks
					r = task.readiness

					if task._id.toString() == @_id.toString()
						r += @readiness

					readiness += r

				callback null, Math.floor readiness / (tasks.length + 1)

			(readiness, callback)->
				model.findById m.parent_task_id, (err, task)->
					task.set 'readiness', readiness
					if readiness == 100
						task.set
							status: 'Выполнена'
							is_completed: true

					task.save callback
		], next

	do next


Models.Task = model

module.exports = (callback)->
	Logger.info 'Task model required'

	do callback
