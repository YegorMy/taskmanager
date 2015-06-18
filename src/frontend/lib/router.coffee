define ['backbone', 'core/baseRouter', 'cookie', 'templates', 'jquery'], (Backbone, BaseRouter, cookie, tpls, $)->
	window.App.templates = tpls

	class Router extends BaseRouter
		routes:
			'': 'feed'
			'newvers': '_new'
			'task': 'index'
			'task/open': 'index'
			'task/closed': 'index'
			'task/projects': 'index'

			'task/new/': 'tasks_new'
			'task/:id': 'task_view'
			'task/:id/edit': 'tasks_new'

			'users': 'users'
			'users/:id': 'user_view'

			'login': 'login'
			'register': 'register'
			'logout': 'logout'

			'lk': 'cabinet'

			'*notFound': '_404'


		noAuth: ['login', 'register']
		preventAccessWidthAuth: ['login', 'register']

		before: (params, next)->
			isAuth        = !!cookie.get 'user'
			path          = (Backbone.history.location.href.replace Backbone.history.location.origin, '').replace /^\//, ''
			needAuth      = !_.contains @noAuth, path
			noAccess      = _.contains @preventAccessWidthAuth, path


			if needAuth && !isAuth
				Backbone.history.navigate 'login', {trigger: true}
			else if isAuth && noAccess
				Backbone.history.navigate '', {trigger: true}
			else
				if !App.user && isAuth
					return $.ajax
						url: '/api/user/' + cookie.get 'user'
						type: 'GET'
						dataType: 'JSON'
						success: (response)->
							if !response.error
								App.user = response

								return do next


							cookie.delete 'user'
							Backbone.history.location.href = '/login'

				do next

		users: ->
			require ['views/usersView', 'models/userCollection'], (v, collection)->
				App.createView v, [collection]

		user_view: (id)->
			require ['views/userSingleView'], (v)->
				App.createView v, [id]

		index: ->
			require ['views/indexView', 'models/taskCollection'], (view, collection)->
				App.createView view, [collection]

		login: ->
			require ['views/loginView', 'models/userModel'], (view, model)->
				new view model

		register: ->
			require ['views/registerView'], (view)->
				new view

		logout: ->
			location.href = '/logout'

		tasks_new: (_id)->
			require ['views/taskEdit', 'models/taskModel'], (view, model, collection, taskCollection)->
				id = null

				if /[=]/.test _id
					_id = null

				if _id
					id = _id
				App.createView view, [model, id]

		task_view: (id)->
			require ['views/taskView', 'models/taskModel'], (view, model)->
				App.createView view, [model, id]

		_404: ->
			console.log 'not found'

		cabinet: ->
			require ['views/lkView', 'models/userCollection'], (view, collection)->
				App.createView view, [collection]

		feed: ->
			require ['views/FeedView', 'models/FeedCollection'], (view, model)->
				App.createView view, [model]

		_new: ->
			require [], ->
				App.createView

	window.App.router = new Router()