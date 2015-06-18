mongoose = require "mongoose"
crypto = require "crypto"
ObjectId = mongoose.Schema.Types.ObjectId

schema = new mongoose.Schema
	login:
		type: String
		unique: true
		required: true

	passwd:
		type: String
		required: true
	name:
		type: String
		required: true
	surname:
		type: String
		required: true
	avatar:
		type: String
		default: '/imgs/basic_avatar.png'

	email: String
	position: String
	dateofbirth: String
	workphone: String
	modphone: String

	status:
		type: String
		enum: ['Занят', 'Свободен', 'В активном поиске']
		default: 'Свободен'

	task_creators:
		type: [ObjectId]
		ref: 'User'

	reg_date:
		type: Date
		default: Date.now

	lastEnter_date:
		type: Date

	token:
		type: String
		unique: true

schema.pre "save", (next)->
	err = null

	if @isModified "passwd"
		@passwd = crypto.createHash('md5').update(@passwd).digest("hex")

	next err

schema.virtual('_name').get ->
	@name + ' ' + @surname

schema.methods.comparePassword = (candidatePassword)->
	crypto.createHash('md5').update(candidatePassword).digest("hex") is @passwd

model = mongoose.model "User", schema

model.formatUser = (user)->
	if user
		id = user._id.toString()

		return {
			id: id
			_id: id
			_name: user.get '_name'
			login: user.get 'login'
			name: user.get 'name'
			surname: user.get 'surname'
			avatar: user.get 'avatar'
			email: user.get 'email'
			status: user.get 'status'
			task_creators: user.get 'task_creators'
		}

	return null

model.byID = (id, callback)->
	model.findById id, (err, user)->
		callback err, model.formatUser user

model.getOne = (query, callback)->
	model.findOne query, (err, user)->
		callback err, model.formatUser user

model._get = (query, callback)->
	model.find query, (err, users)->
		callback err, users.map (e)->
			model.formatUser e


Models.User = model


model.schema.path('login').validate (value)->
	unless value
		return false

	value.length > 3 and value.length < 25 and value != '' and !/\s/.test value

, 'Логин должен содержать от трех до 25 непустых символов.'


model.schema.path('passwd').validate (value)->
	unless value
		return false

	value.length >= 5

, 'Пароль должен содержать больше пяти непустых символов'

module.exports = (callback)->
	Logger.info 'testing user creation'

	model.count {}, (err, count)->
		Logger.info 'User model required'
		unless count
			return model.create
				login: 'user'
				passwd: 'user1'
				name: 'Алёшка'
				surname: 'Васильев'
				, (err, user)->
					if err
						return Logger.error err
					Logger.info "Default user created. Name: user, password: user1"
					callback()


		callback()
