API = require './API'
formidable = require 'formidable'

class UploadFiles extends API
	constructor: (app)->
		super
		@addPath 'files/'

		@initialize app

	initialize: (app)=>
		path = do @getPath


		app.post "#{path}", @index
		app.post "#{path}avatar", @avatar



	index:(req, res)->
		_files = req.files
		keys   = Object.keys _files
		files  = []

		for key in keys
			files.push _files[key]

		res.json files

	avatar:(req, res)->
		if req.files
			if req.files._avatar
				Models.User.findById req.user, (err, user)->
					name = "/uploads/#{req.files._avatar.name}"

					user.set 'avatar', name
					user.save()

					res.json file: name

module.exports = (app, callback)->
	new UploadFiles app
	Logger.info 'Files has been required'

	do callback