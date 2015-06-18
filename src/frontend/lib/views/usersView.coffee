define ['core/baseView'], (BaseView)->
	class View extends BaseView
		tpl: App.templates.users

		initialize: (collection)->
			super

			do @render

			c = new collection

			c.bind 'add', @renderAddUser.bind @
			do c.fetch

		render: ->
			super

			@$el.html @tpl data: {}

			$(@region).html @$el

		renderAddUser: (m)->
			$(App.templates.userListGroupItem user: m.toJSON()).appendTo @$el.find '#users'

	View