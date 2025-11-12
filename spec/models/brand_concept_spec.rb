require 'rails_helper'

RSpec.describe BrandConcept, type: :model do
  describe 'associations' do
    it { should belong_to(:brand) }
  end

  describe 'validations' do
    it { should validate_uniqueness_of(:brand_id) }
  end

  describe 'versioning' do
    it 'has paper trail enabled' do
      expect(described_class).to be_versioned
    end
  end
end
