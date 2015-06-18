define ['jquery'], ($)->
	class BaseView extends Backbone.View
		_tpl: App.templates._layout
		region: '#content'

		serialize: ($form)->
			serialized = $form.serializeArray()
			d          = {}

			for k in serialized
				d[k.name] = k.value

			d

		_destroy: ->
			@$el.remove()

			if @model
				@model.off 'change add remove'
				@model = null

		render: ->
			body = $ 'body'

			unless body.data 'nc-main-render'
				body.data 'nc-main-render', true

				body.html do @_tpl