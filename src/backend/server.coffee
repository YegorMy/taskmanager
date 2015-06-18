# основной файл, который собирает весь проект, подключает модули и делает некоторые преобразования с файлами, чтобы всё было хорошо.

express        = require 'express'
app            = express()
mainController = require './lib/index'
cookieParser   = require 'cookie-parser'
bodyParser     = require 'body-parser'
mongoose       = require 'mongoose'
winston        = require 'winston'
expressWinston = require 'express-winston'
multer         = require 'multer'
global.Models  = {}
multer         = require 'multer' # Работает с заливаемыми файлами.
global.config  = require './lib/config'
exceptions     = ['/api/user/login/', '/api/user/']

winston.loggers.add 'logger',
	console:
		colorize: true

global.Logger = winston.loggers.get 'logger'

mongoose.connect "mongodb://#{config.mongoose.server}/#{config.mongoose.database}"

app.set 'views', "#{__dirname}/views"
app.set 'view engine', 'jade'

app.use express.static __dirname + '/public'

app.use cookieParser()
app.use bodyParser()
app.use expressWinston.logger
	transports: [
		new winston.transports.Console
			colorize: true
	]

app.use multer
	dest: './public/uploads/'

	onFileUploadStart: (file)->
		console.log file.originalname + ' is starting ...'

	onFileUploadComplete: (file)->
		console.log file.fieldname + ' uploaded to  ' + file.path


app.get '*', (req, res, next)->
	if (new RegExp config.api_path, 'i').test req.url
		return next()
	if /logout/i.test req.url
		res.clearCookie 'user'

		return res.redirect '/'

	res.render config.basic_template

app.post '*', (req, res, next)->
	user = req.cookies.user
	url  = req.url

	if url not in exceptions
		unless user
			return res.json error: 'user must be specified in cookies'

		return Models.User.findOne token: user, (err, user)->
			unless user
				return res.json 'error':'user does not exist'

			req.user = user._id.toString()

			do next

	do next

app.get '*', (req, res, next)->
	user = req.cookies.user
	url  = req.url

	if url not in exceptions
		unless user
			return res.json error: 'user must be specified in cookies'

		return Models.User.getOne token: user, (err, user)->
			unless user
				return res.json 'error':'user does not exist'

			req.user = user._id

			do next
	do next

mainController app
app.listen config.port
Logger.info "Server is listening on port #{config.port}"