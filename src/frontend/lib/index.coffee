requirejs.config
	baseUrl: '/js'
	paths:
		underscore: 'libs/underscore-min'
		backbone: 'libs/backbone'
		bootstrap: 'libs/bootstrap.min'
		jquery: 'libs/jquery.min'
		domReady: 'libs/domReady'
		templates: 'templates'
		jade: 'libs/runtime'
		cookie: 'plugins/cookies'
		indexPlugin: 'plugins/indexPlugin'
		datepicker: 'libs/bootstrap-datetimepicker.min'
		multiselect: 'multiselect.min'
		moment: 'libs/moment-with-locales.min'
		async: 'libs/async'
		dropzone: 'libs/dropzone-amd-module.min'
	shim:
		jquery: exports: 'jQuery'
		bootstrap:
			deps: ['jquery']
		backbone:
			deps: ['underscore', 'jquery']
			exports: 'Backbone'
		datepicker:
			deps: ['jquery', 'moment']
		underscore: exports: '_'
		domReady: exports: 'domReady'
		templates: deps: ['jade']
		'backbone-localstorage': deps: ['backbone']
		indexPlugin: deps: ['jquery', 'datepicker', 'multiselect']

window.App = {}

require [
	'domReady'
	'jquery'
	'core/baseFunctions'
	'bootstrap'
	'router'
], (domReady, jquery)->

	jquery.fn.serializeObject = ->
		d  = $(this).serializeArray()
		_d = {}
		
		for k in d
			_d[k.name] = k.value
		
		_d
		
			
	domReady ->
		jquery(document).on 'click', 'a', (e)->
			if this.href && (this.target == '_self' or this.target == '')
				App.router.navigate this.href.replace(location.origin, ''), trigger:true
				do e.preventDefault

		jquery(document).on 'click', '._cancel', (e)->
			do e.preventDefault
			Backbone.history.length -= 2
			do window.history.back


		Backbone.history.start pushState: true