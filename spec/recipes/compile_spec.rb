require 'spec_helper'

describe 'omnibus::_compile' do
  let(:chef_run) { ChefSpec::ServerRunner.converge(described_recipe) }

  it 'includes build-esssential' do
    expect(chef_run).to include_recipe('build-essential::default')
  end

  it 'includes homebrew on OSX' do
    stub_command('which git')
    osx_chef_run = ChefSpec::ServerRunner.new(platform: 'mac_os_x', version: '10.8.2')
                   .converge(described_recipe)
    expect(osx_chef_run).to include_recipe('homebrew::default')
  end

  context 'on freebsd' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new(platform: 'freebsd', version: '10.0')
        .converge(described_recipe)
    end

    it 'Configures BSD Make for backward compat mode' do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/etc/make.conf').and_return(true)
      expect(chef_run).to run_ruby_block('Configure BSD Make for backward compat mode')
    end
  end

  context 'on Solaris 10' do
    let(:chef_run) do
      # Make Solaris 11 look like Solaris 10 as Fauxhai doesn't yet contain
      # data for the latter.
      ChefSpec::ServerRunner.new(platform: 'solaris2', version: '5.11') do |node|
        node.automatic['platform_version'] = '5.10'
      end.converge(described_recipe)
    end

    it 'creates a `make` symlink that points to `gmake`' do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/usr/sfw/bin/gmake').and_return(true)
      expect(chef_run).to create_link('/usr/local/bin/make')
        .with_to('/usr/sfw/bin/gmake')
    end
  end
end
