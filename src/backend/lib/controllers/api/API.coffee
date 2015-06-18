_class = require '../abstract/Class'

class API extends _class
	constructor: ->
		@addPath config.api_path

module.exports = API