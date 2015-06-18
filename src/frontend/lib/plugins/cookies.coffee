define [], ->
	cookie =
		get: (name) ->
			matches = document.cookie.match(new RegExp('(?:^|; )' + name.replace(/([\.$?*|{}\(\)\[\]\\\/\+^])/g, '\\$1') + '=([^;]*)'))

			if matches then decodeURIComponent(matches[1]) else undefined

		set: (name, value, options) ->
			options = options or {}
			expires = options.expires
			if typeof expires == 'number' and expires
				d = new Date
				d.setTime d.getTime() + expires * 1000
				expires = options.expires = d
			if expires and expires.toUTCString
				options.expires = expires.toUTCString()
			value = encodeURIComponent(value)
			updatedCookie = name + '=' + value
			for propName of options
				updatedCookie += '; ' + propName
				propValue = options[propName]
				if propValue != true
					updatedCookie += '=' + propValue
			document.cookie = updatedCookie
			return

		delete: (name) ->
			cookie.set name, '', expires: -1
			return

	cookie