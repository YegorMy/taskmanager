define [
	'underscore'
	'backbone'
], (_, Backbone) ->
	class BaseRouter extends Backbone.Router
		indexRoute: ''
		before: ->
		after: ->
		route: (route, name, callback) ->

			if !_.isRegExp(route)
				route = @_routeToRegExp(route)
			if _.isFunction(name)
				callback = name
				name = ''
			if !callback
				callback = @[name]
			router = this

			Backbone.history.route route, (fragment) ->
				args = router._extractParameters(route, fragment)

				next = ->
					callback and callback.apply(router, args)
					router.trigger.apply router, [ 'route:' + name ].concat(args)
					router.trigger 'route', name, args
					Backbone.history.trigger 'route', router, name, args
					router.after.apply router, args
					return

				router.before.apply router, [
					args
					next
				]

	BaseRouter