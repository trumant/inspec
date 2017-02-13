# encoding: utf-8
# author: Joshua Timberman

require 'helper'
require 'inspec/resource'

describe 'Inspec::Resources::Packages' do
  it 'verify packages resource' do
    resource = MockLoader.new(:ubuntu1604).load_resource('packages', /^vim$/)
    _(resource.entries.length).must_equal 1
    _(resource.entries[0].to_h).must_equal({
      status: 'installed',
      name: 'vim',
      version: '7.4.1689-3ubuntu1.2',
    })
  end

  it 'package name matches with output (string)' do
    resource = MockLoader.new(:ubuntu1604).load_resource('packages', 'xserver-xorg')
    _(resource.to_s).must_equal 'Packages /xserver\\-xorg/'
  end

  it 'packages using where filters' do
    resource = MockLoader.new(:ubuntu1604).load_resource('packages', /.+root$/)
    _(resource.entries.length).must_equal 3
    _(resource.where { status != 'installed' }.names).must_equal(['fakeroot', 'libfakeroot'])
    _(resource.where { version =~ /^0\.2.+/ }.entries[0].to_h).must_equal({
      status: "installed",
      name: "overlayroot",
      version: "0.27ubuntu1.2",
    })
  end

  it 'package name matches with output (regex)' do
    resource = MockLoader.new(:ubuntu1604).load_resource('packages', /vim/)
    _(resource.to_s).must_equal 'Packages /vim/'
  end

  it 'returns a list of packages with a wildcard' do
    resource = MockLoader.new(:ubuntu1604).load_resource('packages', /^xserver-xorg.*/)
    _(resource.statuses).must_equal ['installed']
    _(resource.entries.length).must_equal 3
  end

  it 'all packages on Ubuntu' do
    resource = MockLoader.new(:ubuntu1604).load_resource('packages', /.+/)
    _(resource.entries.length).must_equal 12
  end

  it 'all packages on CentOS' do
    resource = MockLoader.new(:centos6).load_resource('packages', /.+/)
    _(resource.entries.length).must_equal 10
  end

  it 'packages on CentOS' do
    resource = MockLoader.new(:centos6).load_resource('packages', /^chef\-.+/)
    _(resource.entries.length).must_equal 1
    _(resource.where { status == 'installed' }.names).must_equal(['chef-compliance'])
    _(resource.entries[0].to_h).must_equal({
      status: "installed",
      name: "chef-compliance",
      version: "1.3.1-1.el6",
    })
  end

  it 'skips on non debian platforms' do
    resource = MockLoader.new(:hpux).load_resource('packages', 'bash')
    _(resource.resource_skipped).must_equal 'The packages resource is not yet supported on OS hpux'
  end

  it 'fails if the packages name is not a string or regexp' do
    proc {
      resources = MockLoader.new(:ubuntu1604).load_resource('packages', [:a, :b])
      resources.send(:entries, nil)
    }.must_raise(RuntimeError)
  end
end
