require 'spec_helper'

describe Routes::Courses do
  def app
    ExampleApp
  end

  describe 'routes' do
    describe '/courses' do
      it 'renders all courses' do
        visit route('/courses')
        expect(page).to have_content 'All courses'
      end
    end

    describe '/courses/categories' do
      it 'redirects to /courses' do
        get route('/courses/categories')
        expect(last_response.status).to eq 302
      end

      it 'renders /courses' do
        visit route('/courses/categories')
        expect(page).to have_content 'All courses'
      end
    end

    describe '/courses/categories/:slug' do
      it 'renders courses by category' do
        visit route('/courses/categories/getting-started')
        expect(page).to have_content 'Getting started (1)'
      end
    end

    describe '/courses/:slug' do
      it 'renders a course overview' do
        visit route('/courses/hello-contentful')
        expect(page).to have_content 'Table of contents'
        expect(page).to have_content 'Course overview'
        expect(page).to have_content 'Start course'
      end
    end

    describe '/courses/:slug/lessons' do
      it 'redirects to course overview' do
        get route('/courses/hello-contentful/lessons')
        expect(last_response.status).to eq 302
      end

      it 'renders course overview' do
        visit route('/courses/hello-contentful/lessons')
        expect(page).to have_content 'Table of contents'
        expect(page).to have_content 'Course overview'
        expect(page).to have_content 'Start course'
      end
    end

    describe '/courses/:c_slug/lessons/:l_slug' do
      it 'renders a lesson' do
        visit route('/courses/hello-contentful/lessons/architecture')
        expect(page).to have_content 'Go to the next lesson'
      end
    end
  end

  describe 'errors' do
    describe '/courses/:slug' do
      it '404 on unknown slug' do
        visit route('/courses/foo')
        expect(page.status_code).to eq 404
        expect(page).to have_content 'Oops, something went wrong (404)'
      end
    end

    describe '/courses/categories/:slug' do
      it '404 on unknown slug' do
        visit route('/courses/categories/foo')
        expect(page.status_code).to eq 404
        expect(page).to have_content 'Oops, something went wrong (404)'
      end
    end

    describe '/courses/:slug/lessons' do
      it '404 on unknown slug' do
        visit route('/courses/foo/lessons')
        expect(page.status_code).to eq 404
        expect(page).to have_content 'Oops, something went wrong (404)'
      end
    end

    describe '/courses/:c_slug/lessons/:l_slug' do
      it '404 on unknown course slug' do
        visit route('/courses/foo/lessons/architecture')
        expect(page.status_code).to eq 404
        expect(page).to have_content 'Oops, something went wrong (404)'
      end

      it '404 on unknown lesson slug' do
        visit route('/courses/hello-world/lessons/foo')
        expect(page.status_code).to eq 404
        expect(page).to have_content 'Oops, something went wrong (404)'
      end
    end
  end
end
