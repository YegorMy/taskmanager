#  Класс, который инклюдит все остальные модули.

dirs = [
	{name: 'models', require: ['User', 'Task', 'Comment', 'Feed']} # Подключаем модели
	{name: 'controllers', pass: true, require: ['api/User', 'api/Task', 'api/Comment', 'api/Feed', 'api/UploadFiles']} # Подключаем контроллеры. pass означает передавать ли аргумент app в конструктор класса
]
fs    = require 'fs'
async = require 'async'

module.exports = (app)->
	async.eachLimit dirs, 1, ((dir, callback)->
		async.eachLimit dir.require, 1, ((content, callback)->
			args = [callback]
			if dir.pass
				args.unshift app


			(require "./#{dir.name}/#{content}").apply @, args

		), ->
			do callback
	), ->
		Logger.info 'required'