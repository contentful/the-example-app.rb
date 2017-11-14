require 'sinatra/base'
require './routes/base'

module Routes
  class Courses < Base
    get '/courses' do
      courses = contentful.courses(api_id, locale.code)
      categories = contentful.categories(api_id, locale.code)

      # TODO: Attach entry state

      render_with_globals :courses, locals: {
        title: I18n.translate('allCoursesLabel', locale.code),
        courses: courses,
        categories: categories
      }
    end

    get '/courses/categories' do
      redirect to('/courses')
    end

    get '/courses/categories/:category_slug' do |category_slug|
      categories = contentful.categories(api_id, locale.code)
      active_category = categories.detect { |category| category.slug == category_slug }
      courses = contentful.courses_by_category(active_category.id, api_id, locale.code)

      # TODO: Attach entry state

      render_with_globals :courses, locals: {
        title: "#{active_category.title} (#{courses.size})",
        courses: courses,
        categories: categories,
        breadcrumbs: Breadcrumbs.refine(raw_breadcrumbs, active_category)
      }
    end

    get '/courses/:slug' do |slug|
      course = contentful.course(slug, api_id, locale.code)
      lessons = course.lessons

      visited_lessons = session[:visited_lessons] || []
      visited_lessons << course.id unless visited_lessons.include?(course.id)
      session[:visited_lessons] = visited_lessons

      # TODO: Attach entry state

      render_with_globals :course, locals: {
        title: course.title,
        course: course,
        lessons: lessons,
        lesson: nil,
        next_lesson: lessons.first,
        visited_lessons: visited_lessons,
        breadcrumbs: Breadcrumbs.refine(raw_breadcrumbs, course)
      }
    end

    get '/courses/:slug/lessons' do |slug|
      redirect to("/courses/#{slug}")
    end

    get '/courses/:course_slug/lessons/:lesson_slug' do |course_slug, lesson_slug|
      course = contentful.course(course_slug, api_id, locale.code)
      lessons = course.lessons
      lesson = lessons.detect { |lesson| lesson.slug == lesson_slug }

      visited_lessons = session[:visited_lessons] || []
      visited_lessons << lesson.id unless visited_lessons.include?(lesson.id)
      session[:visited_lessons] = visited_lessons

      next_lesson = next_lesson(lessons, lesson.slug)

      # TODO: Attach entry state

      render_with_globals :course, locals: {
        title: course.title,
        course: course,
        lessons: lessons,
        lesson: lesson,
        next_lesson: next_lesson,
        visited_lessons: visited_lessons,
        breadcrumbs: Breadcrumbs.refine(
          Breadcrumbs.refine(raw_breadcrumbs, course),
          lesson
        )
      }
    end

    def next_lesson(lessons, lesson_slug = nil)
      return lessons.first if lesson_slug.nil?

      lessons.each_with_index do |lesson, index|
        return lessons[index + 1] if lesson.slug == lesson_slug
      end
    end
  end
end
