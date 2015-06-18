define ['backbone'], (Backbone)->
	class UserModel extends Backbone.Model
		defaults:
			login: ''
			passwd: ''
		url: '/api/user/'
		idAttribute: '_id'


		validate: (a, options)->
			if !a.login or !a.passwd
				return 'Поля "Логин" и "Пароль" обязательны для заполнения'
	UserModel