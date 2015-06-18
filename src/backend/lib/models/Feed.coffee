mongoose = require 'mongoose'
mongooseSchena = mongoose.Schema
oID = mongooseSchena.Types.ObjectId

schema = new mongooseSchena
	for:
		type: oID
		ref: 'User'
	readiness:
		type: Number
		default: 0
	user_id:
		type: oID
		ref: 'User'
	created_date:
		type: Date
		default: Date.now
	task_id:
		type: oID
		ref: 'Task'
	feed_type:
		type: String
		enum: ['add_responsible', 'add_performer', 'remove_responsible', 'remove_performer', 'status_change', 'declined', 'add_subtask', 'edit_task', 'add_comment', 'completed']

Models.Feed = mongoose.model 'Feed', schema

module.exports = (callback)->
	Logger.info 'Feed model required'
	do callback