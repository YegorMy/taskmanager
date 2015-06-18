define ['jquery', 'core/baseView'], ($, BaseView)->
	class IndexView extends BaseView
		tpl: App.templates.feed
		collection: {}

		initialize: (collection)->
			super

			c = new collection

			c.on 'add', @renderAdd
			c.on 'change remove', @render


			do c.fetch

			do @render

		render: (data = {})=>
			super

			@$el.html @tpl data

			$(@region).html @$el

		renderAdd: (data)=>
			d = data.toJSON()

			f =
				add_responsible: "Добавил вас как ответственного в задаче"
				add_performer: "Добавил вас как исполнителя в задаче"
				remove_responsible: "Удалил вас как ответственного в задаче"
				remove_performer: "Удалил вас как исполнителя в задаче"
				status_change: "Сменил готовность на %readiness% в задаче"
				declined: "Отменил задачу"
				add_subtask: "Создал подзадачу в " + if d.task_id.project then 'задаче' else 'проекте'
				edit_task: "Отредактировал задачу"
				add_comment: "Добавил комментарий к задаче"
				completed: "Выполнил задачу"

			d.feed_text = f[d.feed_type]
			date = new Date d.created_date
			console.log d

			d.formated_created_date = addZero(date.getDate()) + "." + addZero(date.getMonth() + 1) + '.' + date.getFullYear() + ' ' + addZero(date.getHours()) + ':' + addZero(date.getMinutes()) + ':' + addZero(date.getSeconds())

			$('#feed').append $ App.templates.feedItem data: d

	addZero = (n)->
		if n < 9 then '0' + n else n


	IndexView
