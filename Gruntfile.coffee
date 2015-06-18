module.exports = (grunt)->

	src = "src"
	out = "out"
	paths =
		out: out
		src: src
		common: "#{src}/common"
		backend: "#{src}/backend"
		frontend: "#{src}/frontend"
		target: "#{out}"
		public: "#{out}/public"
		bower: "bower_components/"

	grunt.initConfig

		clean:
			files:src: [paths.out]
			options:
				force: true

		coffee:
			options:
				bare: true

			frontend:
				expand: true
				cwd: "#{paths.frontend}/lib"
				src: ["**/*.coffee"]
				dest: "#{paths.public}/js/"
				ext: ".js"

			backend:
				expand: true
				cwd: "#{paths.backend}/"
				src: ["**/*.coffee", '*.coffee']
				dest: "#{paths.target}"
				ext: ".js"

		requirejs:
			common:
				options:
					name: "index"
					optimize: "none"
					baseUrl: "#{paths.public}/js/"
					mainConfigFile: "#{paths.public}/js/index.js"
					out: "#{paths.public}/js/index.js"
		copy:
			assets:files: [
				expand: true
				cwd: "#{paths.frontend}/assets"
				src: ["**/*"]
				dest: "#{paths.public}"
			]
			jade:files: [
				expand: true
				cwd: "#{paths.backend}/views"
				src: ["**/*.jade"]
				dest: "#{paths.target}/views"
			]
			fonts:files:[
				expand: true
				flatten: true
				cwd: "bower_components/"
				src: [
					"bootstrap/dist/fonts/*"
					"font-awesome/fonts/*"
				]
				dest: "#{paths.public}/fonts"
			]
			css:files:[
				expand: true
				flatten: true
				cwd: "#{paths.frontend}/assets/css/"
				src: [
					"*.css, **/*"
				]
				dest: "#{paths.public}/css/"
			]
			bower: files: [
				expand: true
				flatten: true
				cwd: paths.bower
				src: [
					'jquery/jquery.min.*'
					'jquery/dist/jquery.min.*'
					'backbone/backbone.js'
					'underscore/underscore-min.*'
					'backbone-localstorage/backbone-localstorage.min.js'
					'backbone-validation/dist/backbone-validation.min.js'
					'domReady/domReady.js'
					'requirejs/require.js'
					'jade/runtime.js'
					'bootstrap/dist/js/bootstrap.min.js'
					'async/lib/async.js'
					'moment/min/moment-with-locales.min.js'
					'eonasdan-bootstrap-datetimepicker/build/js/bootstrap-datetimepicker.min.js'
				]
				dest: "#{paths.public}/js/libs/"
			]
			config: files: [
				expand: true
				flatten: true
				cwd: "#{paths.backend}/lib/config/"
				src: ['config.json']
				dest: "#{paths.out}/lib/config/"
			]
		less:
			debug:
				files: [
					src: "#{paths.frontend}/less/common.less"
					dest: "#{paths.public}/css/common.css"
				]
			release:
				files: [
					src: ["#{paths.frontend}/less/common.less"]
					dest: "#{paths.public}/css/common.css"
				]
				options:
					yuicompress: true

		jade:
			options:
				client: true
				compileDebug: false
				amd: true
				processName: (filename)->
					filename.substring filename.lastIndexOf("/") + 1, filename.lastIndexOf(".jade")
			compile:
				files: [
					src: "#{paths.frontend}/lib/templates/**/*.jade"
					dest: "#{paths.public}/js/templates.js"
				]

		watch:
			JS:
				files: ['**/**/*.js', 'index.js']
				tasks: ['copy:JS']
				options:
					cwd: "#{paths.frontend}/assets/js/"

			frontend:
				files: ['**/*.coffee']
				tasks: ['coffee:frontend', 'requirejs']
				options:
					cwd: "#{paths.frontend}/lib/"

			coffee_backend:
				files: '**/*.coffee'
				tasks: ['coffee:backend']
				options:
					cwd: "#{paths.backend}/"
			coffee_frontend:
				files: '**/*.coffee'
				tasks: ['coffee:frontend']
				options:
					cwd: "#{paths.frontend}/coffee/"
			jade_backend:
				files: '**/*.jade'
				tasks: ['copy:jade']
				options:
					cwd: "#{paths.backend}/views"
			locales:
				files: '**/*.json'
				tasks: ['copy:locales']
				options:
					cwd: "#{paths.backend}/locales"
			less:
				files: '**/*.less'
				tasks: ['less:debug']
				options:
					cwd: "#{paths.frontend}/less"
			css:
				files: "#{paths.frontend}/assets/css/*.css"
				tasks: ['copy:assets']
			jade_frontend:
				files: "#{paths.frontend}/**/*.jade"
				tasks: ['jade', 'coffee:frontend', 'requirejs']

		nodemon:
			options:
				cwd: "#{paths.target}"
			debug:
				script: "server.js"
				options:
					nodeArgs: ['--debug']

			trace:
				script: "server.js"
				options:
					nodeArgs: ['--debug-brk']

			release: {
				script: "server.js"
			}

		concurrent:
			options:
				logConcurrentOutput: true
			debug:
				tasks: ['nodemon:debug', 'watch']
			trace:
				tasks: ['nodemon:trace', 'watch']

	grunt.registerTask 'build', (arg)->
		buildType = arguments[0] ? "debug"
		if buildType not in ['debug', 'release', 'trace']
			grunt.log.error "Wrong build type specified"
			false
		else
			grunt.log.ok "Build type: #{buildType}"

			switch buildType
				when "debug", "trace" then grunt.task.run 'clean','copy', 'less:debug', 'coffee', 'jade', 'requirejs'
				when "release" then grunt.task.run 'clean','copy', 'less:release', 'coffee', 'jade', 'requirejs'
				else
					grunt.log.error "Wrong build type specified"
					false

	grunt.registerTask 'run', (arg)->
		buildType = arguments[0] ? "debug"
		environment = arguments[1] ? "development"

		if environment not in ['development', 'production']
			grunt.log.error "Wrong environment specified"
			false

		grunt.log.ok "Runtime environment: #{environment}"

		grunt.task.run "build:#{buildType}", if buildType is "release" then "nodemon:release" else "concurrent:#{buildType}"

	grunt.registerTask 'trace', ['run:trace']
	grunt.registerTask 'debug', ['run:debug']
	grunt.registerTask 'release', ['run:release:production']
	grunt.registerTask 'default', ['run']

	grunt.loadNpmTasks "grunt-contrib-requirejs"
	grunt.loadNpmTasks "grunt-contrib-clean"
	grunt.loadNpmTasks "grunt-contrib-coffee"
	grunt.loadNpmTasks "grunt-contrib-copy"
	grunt.loadNpmTasks "grunt-contrib-less"
	grunt.loadNpmTasks "grunt-contrib-watch"
	grunt.loadNpmTasks "grunt-concurrent"
	grunt.loadNpmTasks "grunt-contrib-jst"
	grunt.loadNpmTasks "grunt-contrib-jade"
	grunt.loadNpmTasks "grunt-contrib-cssmin"
	grunt.loadNpmTasks "grunt-nodemon"
	grunt.loadNpmTasks "grunt-env"
