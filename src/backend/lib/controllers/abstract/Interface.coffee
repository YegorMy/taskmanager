# Собственно, сам CRUD класс.

###

    Есть четыре базисных действия, которые можно делать с данными: создавать, удалять, редактировать и просматривать.
    Соотвественно, существуют четыре функции list, del, save, update.
    Функция list имеет аналог single, когда показываются не все элементы коллекции, а только один по id, переданному в url.

    Для вмешательство в работу программы существуют пара функций, в аргументы которой передаются нужные нам значения.
    onBeforeUpdate -- Перед тем, как функция запишет что-то в базу/изменит что-то в базе, можно изменить данные или что-то иное сделать
    onBeforeDelete -- Перед удалением, соответственно, можно так-же что-то сделать. Данные изменить нельзя, потому что удаляется по id.
    onBeforeListShow и onBeforeSingleShow -- При показе всех / конкретного элемента из базы.

    onBefore*Query -- синхронная функция, которая изменяет только запрос, который позволяет специфицировать выборку.

###

class Interface
	path:  ''
	model: {}

	constructor: (app)->
		@renderPath = @path.substr 1
		app.get "#{@path}", @list
		app.get "#{@path}new/", @single
		app.get "#{@path}edit/:id", @single
		app.get "#{@path}delete/:id", @del


		app.post "#{@path}new/", @save
		app.post "#{@path}edit/:id", @update


	list: (req, res)=>
		self  = @
		query = @onBeforeListShowQuery @model.find {}

		query.exec (err, data)->
			self.onBeforeListShow req, res, data:data, (res, data)->
				res.render "#{self.renderPath}list", self.sendData data

	single: (req, res)=>
		id    = req.params.id
		self  = @
		query = @onBeforeSingleShowQuery @model.findById id

		query.exec (err, data)->
			self.onBeforeSingleShow req, res, data:data, (res, data)->
				res.render "#{self.renderPath}single", self.sendData data

	del: (req, res)=>
		path  = @path
		model = @model

		@onBeforeDelete req, ->
			model.findByIdAndRemove req.params.id, (err)->
				throw err if err

				res.redirect path

	save: (req, res)=>
		data  = req.body
		self  = @
		model = self.model
		path  = self.path

		@onBeforeUpdate req, data, (data)->
			m = new model data

			m.save (err)->
				throw new Error err if err
				res.redirect path
		, true

	update: (req, res)=>
		id    = req.params.id
		data  = req.body
		path  = @path
		model = @model

		@onBeforeUpdate req, data, (data)->
			model.findById id, (err, entity)->
				throw new err if err

				entity.set data

				entity.save (err)->
					throw err if err

				res.redirect path

	onBeforeListShowQuery: (query)->
		query

	onBeforeSingleShowQuery: (query)->
		query

	onBeforeListShow: (req, res, data, callback)->
		callback res, data

	onBeforeSingleShow: (req, res, data, callback)->
		callback res, data

	onBeforeDelete: (data, callback)->
		callback data

	onBeforeUpdate: (req, data, callback, isNew)->
		callback data

	sendData: (data)=>
		data.path = @path

		data


module.exports = Interface