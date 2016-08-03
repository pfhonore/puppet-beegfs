require 'spec_helper'

describe 'beegfs::storage' do
  let(:hiera_data) { { 'beegfs::mgmtd_host' => "foo.bar" } }

  let(:facts) do
    {
    :operatingsystem => 'Debian',
    :osfamily => 'Debian',
    :lsbdistcodename => 'wheezy',
    :lsbdistid => 'Debian',
  }
  end

  let(:user) { 'beegfs' }
  let(:group) { 'beegfs' }

  let(:params) do
    {
    'user'  => user,
    'group' => group,
    :major_version => '2015.03',
  }
  end

  it { is_expected.to contain_class('beegfs::storage') }

  shared_examples 'debian-storage' do |os, codename|
    let(:facts) do
      {
      :operatingsystem => os,
      :osfamily => 'Debian',
      :lsbdistcodename => codename,
      :lsbdistid => 'Debian',
    }
    end

    it { should contain_package('beegfs-utils') }
    it do
      should contain_service('beegfs-storage').with(
        :ensure => 'running',
        :enable => true
      )
    end

    it do
      is_expected.to contain_file('/etc/beegfs/beegfs-storage.conf').with({
        'ensure'  => 'present',
        'owner'   => user,
        'group'   => group,
        'mode'    => '0755',
      })
    end

    it do
      is_expected.to contain_file('/srv/beefgs/storage').with({
        'ensure'  => 'directory',
        'owner'   => user,
        'group'   => group,
      })
    end

    it do
      is_expected.to contain_service('beegfs-storage').with(
        :ensure => 'running',
        :enable => true
      )
    end
  end

  context 'on debian-like system' do
    let(:user) { 'beegfs' }
    let(:group) { 'beegfs' }

    let(:params) do
      {
      'user'  => user,
      'group' => group,
      :major_version => '2015.03',
      :storage_directory => '/srv/beefgs/storage'
    }
    end

    it_behaves_like 'debian-storage', 'Debian', 'wheezy'
    it_behaves_like 'debian-storage', 'Ubuntu', 'precise'
  end

  context 'with given version' do
    let(:version) { '2012.10.r8.debian7' }
    let(:params) do
      {
      :package_ensure => version,
      :major_version  => '2015.03',
    }
    end

    it do
      should contain_package('beegfs-storage').with({
      'ensure' => version
    })
    end
  end

  it do
    should contain_file('/etc/beegfs/interfaces.storage').with({
    'ensure'  => 'present',
    'owner'   => user,
    'group'   => group,
    'mode'    => '0755',
  }).with_content(/eth0/)
  end

  context 'interfaces file' do
    let(:params) do
      {
      :interfaces      => ['eth0', 'ib0'],
      :interfaces_file => '/etc/beegfs/store.itf',
      :user            => user,
      :group           => group,
      :major_version   => '2015.03',
    }
    end

    it do
      should contain_file('/etc/beegfs/store.itf').with({
      'ensure'  => 'present',
      'owner'   => user,
      'group'   => group,
      'mode'    => '0755',
    }).with_content(/ib0/)
    end


    it do
      should contain_file(
        '/etc/beegfs/beegfs-storage.conf'
      ).with_content(/connInterfacesFile(\s+)=(\s+)\/etc\/beegfs\/store.itf/)
    end
  end

  it do
    should contain_file(
      '/etc/beegfs/beegfs-storage.conf'
    ).with_content(/logLevel(\s+)=(\s+)3/)
  end

  context 'changing log level' do
    let(:params) do
      {
      :log_level => 5,
      :major_version => '2015.03',
    }
    end

    it do
      should contain_file(
        '/etc/beegfs/beegfs-storage.conf'
      ).with_content(/logLevel(\s+)=(\s+)5/)
    end
  end

  context 'set mgmtd host' do
    let(:params) do
      {
      :mgmtd_host => 'mgmtd.beegfs.com',
      :major_version => '2015.03',
    }
    end

    it do
      should contain_file(
        '/etc/beegfs/beegfs-storage.conf'
      ).with_content(/sysMgmtdHost(\s+)=(\s+)mgmtd.beegfs.com/)
    end
  end

  context 'set mgmtd tcp port' do
    let(:params) do
      {
      :mgmtd_tcp_port => 9009,
      :major_version  => '2015.03',
    }
    end

    it do
      should contain_file(
        '/etc/beegfs/beegfs-storage.conf'
      ).with_content(/connMgmtdPortTCP(\s+)=(\s+)9009/)
    end
  end
end
