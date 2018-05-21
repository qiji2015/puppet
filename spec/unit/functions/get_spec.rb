require 'spec_helper'

require 'puppet_spec/compiler'
require 'matchers/resource'

describe 'the get function' do
  include PuppetSpec::Compiler
  include Matchers::Resource

  context 'returns undef value' do
    it 'when result is undef due to missing variable' do
      expect( evaluate(source: "get('$x')")).to be_nil
    end

    it 'when result is undef due to resolved undef variable value' do
      expect( evaluate(source: "$x = undef; get('$x')")).to be_nil
    end

    it 'when result is undef due to given undef' do
      expect( evaluate(source: "get(undef, '')")).to be_nil
    end

    it 'when result is undef due to navigation into undef' do
      expect( evaluate(source: "get(undef, '0')")).to be_nil
    end

    it 'when navigation results in explicit undef in an array' do
      expect( evaluate(source: "get([undef], '0')")).to be_nil
    end

    it 'when navigation results in explicit undef in a hash' do
      expect( evaluate(source: "get(a => undef, 'a')")).to be_nil
    end

    it 'when navigation references unavailable value in an array' do
      expect( evaluate(source: "get([1], '2')")).to be_nil
    end

    it 'when navigation references unavailable value in a hash' do
      expect( evaluate(source: "get(a => 43, 'b')")).to be_nil
    end
  end

  context 'returns default value' do
    it 'when result is undef due to missing variable' do
      expect( evaluate(source: "get('$x', 'ok')")).to eql('ok')
    end

    it 'when result is undef due to resolved undef variable value' do
      expect( evaluate(source: "$x = undef; get('$x', 'ok')")).to eql('ok')
    end

    it 'when result is undef due to given undef' do
      expect( evaluate(source: "get(undef, '', 'ok')")).to eql('ok')
    end

    it 'when result is undef due to navigation into undef' do
      expect( evaluate(source: "get(undef, '0', 'ok')")).to eql('ok')
    end

    it 'when navigation results in explicit undef in array' do
      expect( evaluate(source: "get([undef], '0', 'ok')")).to eql('ok')
    end

    it 'when navigation results in explicit undef in hash' do
      expect( evaluate(source: "get(a => undef, 'a', 'ok')")).to eql('ok')
    end

    it 'when navigation references unavailable value in an array' do
      expect( evaluate(source: "get([1], '2', 'ok')")).to eql('ok')
    end

    it 'when navigation references unavailable value in a hash' do
      expect( evaluate(source: "get(a => 43, 'b', 'ok')")).to eql('ok')
    end
  end

  it 'returns value of $variable if given single string' do
    expect(evaluate(source: "$x = 'testing'; get('$x')")).to eql('testing')
  end

  it 'navigates into $variable if given dot syntax after variable name' do
    expect(
      evaluate(
        variables: {'x'=> ['nope', ['ok']]},
        source: "get('$x.1.0')"
      )
    ).to eql('ok')
  end

  it 'navigates into array as given by navigation string' do
    expect( evaluate( source: "get(['nope', ['ok']], '1.0')")).to eql('ok')
  end

  it 'navigates into hash as given by navigation string' do
    expect( evaluate( source: "get(a => 'nope', b=> ['ok'], 'b.0')")).to eql('ok')
  end

  it 'navigates into hash with numeric key' do
    expect( evaluate( source: "get(a => 'nope', 0=> ['ok'], '0.0')")).to eql('ok')
  end

  it 'navigates into hash with numeric string but requires quoting' do
    expect( evaluate( source: "get(a => 'nope', '0'=> ['ok'], '\"0\".0')")).to eql('ok')
  end

  it 'can navigate a key with . when it is quoted' do
    expect(
        evaluate(
            variables: {'x'=> {'a.b' => ['nope', ['ok']]}},
            source: "get('$x.\"a.b\".1.0')"
        )
    ).to eql('ok')
  end

  it 'when navigating with string key into an array an error is raised' do
    expect{ evaluate( source: "get(['nope', ['ok']], '1.blue')")}.to raise_error(/no implicit conversion/)
  end

  it 'calls a given block with EXPECTED_INTEGER_INDEX if navigating into array with string' do
    expect( evaluate(
        source: "get(['nope', ['ok']], '1.blue') |$msg| {
                   if $msg =~ /^EXPECTED_INTEGER_INDEX$/ {'ok'} else { 'nope'}
                 }"
    )).to eql('ok')
  end

  it 'calls a given block with EXPECTED_COLLECTION if navigating into something not Undef or Collection' do
    expect( evaluate(
                source: "get(['nope', /nah/], '1.blue') |$msg| {
                           if $msg =~ /^EXPECTED_COLLECTION$/ {'ok'} else { 'nope'}
                         }"
            )).to eql('ok')
  end

  it 'does not call a given block if navigation string has syntax error' do
    expect{ evaluate(
                source: "get(['nope', /nah/], '1....') |$msg| {
                           fail('so sad')
                         }"
            )}.to raise_error(/Syntax error/)
  end

end
