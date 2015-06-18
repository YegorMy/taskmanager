define ['indexPlugin'], (doPlugin)->
	BaseFunctions =
		_view:
			_destroy: ->

		createView: (view, args)->

			do BaseFunctions._view._destroy


			f = ->
				view.apply(this, args)

			f.prototype = view.prototype

			BaseFunctions._view = new f

			do doPlugin

		assignData: (data)->
			d      = data
			d.user = App.user

			return d

		format: (date)->
			d = new Date date

			return addZero(d.getDate()) + '.' + addZero(d.getMonth() + 1) + '.' + d.getFullYear() + ' в ' + addZero(d.getHours()) + ':' + addZero(d.getMinutes()) + ':' + addZero(d.getSeconds())

	addZero = (num)->
		if num < 9 then '0' + num else num


	window.App = _.extend {}, BaseFunctions