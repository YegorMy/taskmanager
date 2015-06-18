define [], ->
	
	class Person extends Backbone.Model
		urlRoot: '/api/user/'
		
		validate: (d)->
			fields    = 
				email: 'Эл. почта'
				passwd: 'Пароль'
				passwd1: 'Повтор пароля'
				name: 'Имя'
				surname: 'Фамилия'
				pos: 'Должность'
				dateofbirth: 'Дата рождения'
				workphone: 'Рабочий телефон'
				mobphone: 'Мобильный телефон'
				
			for k of fields
				if d[k] is ''
					return "Поле #{fields[k]} не может быть пустым."
					
			unless /.+@.+\..+/.test d.email
				return 'Почта введена неверно. Пример: example@example.com'
				
			if d.passwd isnt d.passwd1
				return 'Введенные пароли не совпадают'
		
		true	
	Person