mongoose = require 'mongoose'
mongooseSchena = mongoose.Schema
oID = mongooseSchena.Types.ObjectId

schema = new mongooseSchena
	text: String
	user_id:
		type: oID
		ref: 'User'
	created_date:
		type: Date
		default: Date.now
	task_id:
		type: oID
		res: 'Task'
	files: [
		{
			name: String
			originalname: String
		}
	]

Models.Comment = mongoose.model 'Comment', schema

module.exports = (callback)->
	Logger.info 'Comment model required'
	do callback