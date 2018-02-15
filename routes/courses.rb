require 'sinatra/base'
require './routes/base'

module Routes
  class Courses < Base
    get '/courses' do
      wrap_errors do
        courses = contentful.courses(api_id, locale.code)
        categories = contentful.categories(api_id, locale.code)

        courses.each { |course| attach_entry_state(course) if attach_entry_state? }

        render_with_globals :courses, locals: {
          title: "#{I18n.translate('allCoursesLabel', locale.code)} (#{courses.size})",
          courses: courses,
          categories: categories
        }
      end
    end

    get '/courses/categories' do
      redirect to('/courses')
    end

    get '/courses/categories/:category_slug' do |category_slug|
      wrap_errors do
        categories = contentful.categories(api_id, locale.code)
        active_category = categories.detect { |category| category.slug == category_slug }
        return not_found_error(I18n.translate('errorMessage404Category', locale.code)) if active_category.nil?

        courses = contentful.courses_by_category(active_category.id, api_id, locale.code)

        courses.each { |course| attach_entry_state(course) if attach_entry_state? }

        render_with_globals :courses, locals: {
          title: "#{active_category.title} (#{courses.size})",
          courses: courses,
          categories: categories,
          breadcrumbs: Breadcrumbs.refine(raw_breadcrumbs, active_category)
        }
      end
    end

    get '/courses/:slug' do |slug|
      wrap_errors do
        course = contentful.course(slug, api_id, locale.code)
        return not_found_error(I18n.translate('errorMessage404Course', locale.code)) if course.nil?

        lessons = course.lessons

        visited_lessons = session[:visited_lessons] || []
        visited_lessons << course.id unless visited_lessons.include?(course.id)
        session[:visited_lessons] = visited_lessons

        attach_entry_state(course) if attach_entry_state?

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
    end

    get '/courses/:slug/lessons' do |slug|
      redirect to("/courses/#{slug}")
    end

    get '/courses/:course_slug/lessons/:lesson_slug' do |course_slug, lesson_slug|
      wrap_errors do
        course = contentful.course(course_slug, api_id, locale.code)
        return not_found_error(I18n.translate('errorMessage404Course', locale.code)) if course.nil?

        lessons = course.lessons
        lesson = lessons.detect { |lesson| lesson.slug == lesson_slug }
        return not_found_error(I18n.translate('errorMessage404Lesson', locale.code)) if lesson.nil?

        visited_lessons = session[:visited_lessons] || []
        visited_lessons << lesson.id unless visited_lessons.include?(lesson.id)
        session[:visited_lessons] = visited_lessons

        next_lesson = next_lesson(lessons, lesson.slug)

        attach_entry_state(course) if attach_entry_state?
        attach_entry_state(lesson) if attach_entry_state?

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
    end

    # Helper to get the next lesson with the current lesson slug
    def next_lesson(lessons, lesson_slug = nil)
      return lessons.first if lesson_slug.nil?

      lessons.each_with_index do |lesson, index|
        return lessons[index + 1] if lesson.slug == lesson_slug
      end
    end
  end
end
