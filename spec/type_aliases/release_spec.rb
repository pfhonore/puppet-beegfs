# frozen_string_literal: true

require 'spec_helper'

describe 'Beegfs::Release' do
  it { is_expected.to allow_value('2015.03') }
  it { is_expected.to allow_value('6.0') }
  it { is_expected.to allow_value('7.1') }
  it { is_expected.to allow_value('8') }
end
