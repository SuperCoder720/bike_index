require 'spec_helper'

describe FeedbacksController do
  describe 'index' do
    context 'legacy' do
      it 'renders with content layout' do
        get :index
        expect(response.status).to eq(200)
        expect(response).to render_template(:index)
        expect(response).to render_with_layout('content')
      end
    end
    context 'revised' do
      it 'renders with revised_layout' do
        allow(controller).to receive(:revised_layout_enabled?) { true }
        get :index
        expect(response.status).to eq(200)
        expect(response).to render_template(:index)
        expect(response).to render_with_layout('application_revised')
      end
    end
  end
end
