define ['backbone', 'models/userModel'], (backbone, userModel)->
	class UserCollection extends backbone.Collection
		model: userModel
		url: '/api/user/'

	initialize: (params)->
		console.log arguments
		if params
			if params.taskCreators
				@url += '?task_creators=true'

	UserCollection