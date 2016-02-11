require 'spec_helper'
describe 'ozmt' do

  context 'with defaults for all parameters' do
    it { should contain_class('ozmt') }
  end
end
