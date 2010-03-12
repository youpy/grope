require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Grope::EffectiveTldNames do
  before do
    @effective_tld_names = Grope::EffectiveTldNames.parse(File.dirname(__FILE__) +
      '/../data/effective_tld_names.dat')
  end

  it "should have names" do
    @effective_tld_names.names.should_not be_empty
    @effective_tld_names.wildcard_names.should_not be_empty
    @effective_tld_names.exception_names.should_not be_empty
  end

  it "should match effective name" do
    @effective_tld_names.match('jp').should be_true
    @effective_tld_names.match('.jp').should be_true
    @effective_tld_names.match('foo.akita.jp').should be_true
    @effective_tld_names.match('metro.tokyo.jp').should be_false
  end
end

