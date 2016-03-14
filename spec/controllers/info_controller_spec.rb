require 'spec_helper'

describe InfoController do
  describe :about do
    before do
      get :about
    end
    it { should respond_with(:success) }
    it { should render_template(:about) }
  end

  describe :protect_your_bike do
    before do
      get :protect_your_bike
    end
    it { should respond_with(:success) }
    it { should render_template(:protect_your_bike) }
  end

  describe :where do
    before do
      FactoryGirl.create(:country, iso: "US")
      get :where
    end
    it { should respond_with(:success) }
    it { should render_template(:where) }
  end

  describe :serials do
    before do
      get :serials
    end
    it { should respond_with(:success) }
    it { should render_template(:serials) }
  end

  describe :image_resources do
    before do
      get :image_resources
    end
    it { should respond_with(:success) }
    it { should render_template(:image_resources) }
  end

  describe :privacy do
    before do
      get :privacy
    end
    it { should respond_with(:success) }
    it { should render_template(:privacy) }
  end

  describe :terms do
    before do
      get :terms
    end
    it { should respond_with(:success) }
    it { should render_template(:terms) }
  end

  describe :vendor_terms do
    before do
      get :vendor_terms
    end
    it { should respond_with(:success) }
    it { should render_template(:vendor_terms) }
  end

  describe :resources do
    before do
      get :resources
    end
    it { should respond_with(:success) }
    it { should render_template(:resources) }
  end

  describe :support_the_index do
    before do
      get :support_the_index
    end
    it { should respond_with(:success) }
    it { should render_template(:support_the_index) }
  end

end
