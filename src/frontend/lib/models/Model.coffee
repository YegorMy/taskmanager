define ['backbone', 'core/Error'], (B, Error)->
	class Model extends B.Model
		_data: {}
		constructor: (data)->
			d = {}
			
			for k in data
				d[k.name] = k.value
			
			@_data = d
			
		error: (text)->
			new Error text
			
	Model