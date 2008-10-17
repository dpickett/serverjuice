require 'test/unit'
require 'rubygems'
require 'shoulda'

require 'serverjuice'

class Array
  def chomp_last!
    last.chomp!
    self
  end
end

class ServerJuiceTest < Test::Unit::TestCase
  context "Default generated script" do
    setup do
      @script = ServerJuice.new('test_juicer', 'example.com', 'tasty').generate

      @generated = @script.split(/\n\n/).chomp_last!

      @header, @configuration, @require_hostname, @set_hostname, @upgrade_system_packages,
      @install_essential_tools, @install_apache2, @install_mysql_server, @install_git,
      @install_core_ruby, @install_ruby_mysql, @install_rubygems, @install_rails,
      @install_passenger = <<EOS.split(/\n\n/).chomp_last!
# test_juicer.sh:
#
# Set up a clean Ubuntu 8.04 install for Rails production deployment.
#
# Tested on:
#
# linode.com - Ubuntu 8.04 LTS
#

# Configure your desired options here
DESIRED_HOSTNAME="tasty"
RI="--no-ri"                         # Comment to install ri
RDOC="--no-rdoc"                     # Comment to install RDOC

# Ensure hostname is configured
if [ -z "$DESIRED_HOSTNAME" ]; then
	echo DESIRED_HOSTNAME must be set.
	exit 1
fi

# Set hostname
echo "$DESIRED_HOSTNAME" >/etc/hostname
sed -re "s/^(127.0.1.1[[:space:]]+).*/\\1$DESIRED_HOSTNAME/" </etc/hosts >"test_juicer.tmp" && cp -f "test_juicer.tmp" /etc/hosts && rm -f "test_juicer.tmp"
/etc/init.d/hostname.sh start

# Upgrade system packages
apt-get -y update
apt-get -y upgrade

# Install essential tools
apt-get -y install build-essential wget

# Install Apache 2
apt-get -y install apache2 apache2-prefork-dev

# Install MySQL Server
apt-get -y install mysql-server mysql-client libmysqlclient15-dev

# Install Git
apt-get -y install git-core

# Install Core Ruby
apt-get -y install ruby-full

# Install Ruby MySQL driver
apt-get -y install libmysql-ruby1.8

# Install RubyGems
(
RUBYGEMS=rubygems-1.3.0 &&
cd /usr/local/src &&
rm -rf $RUBYGEMS $RUBYGEMS.tgz &&
# Note: Filename in URL does not determine which file to download
wget http://rubyforge.org/frs/download.php/43985/rubygems-1.3.0.tgz &&
tar -xzf $RUBYGEMS.tgz &&
cd $RUBYGEMS &&
ruby setup.rb $RDOC $RI &&
ln -sf /usr/bin/gem1.8 /usr/bin/gem &&
cd .. &&
rm -rf $RUBYGEMS $RUBYGEMS.tgz
)

# Install Rails
gem install $RDOC $RI rails

# Install and setup Passenger
gem install $RDOC $RI passenger
(echo; echo) | passenger-install-apache2-module
cat >/etc/apache2/conf.d/passenger <<EOP
LoadModule passenger_module /usr/lib/ruby/gems/1.8/gems/passenger-2.0.3/ext/apache2/mod_passenger.so
PassengerRoot /usr/lib/ruby/gems/1.8/gems/passenger-2.0.3
PassengerRuby /usr/bin/ruby1.8
EOP
apache2ctl graceful
EOS
    end

    should "contain expected sections" do
      assert_equal @header, @generated.shift
      assert_equal @configuration, @generated.shift
      assert_equal @require_hostname, @generated.shift
      assert_equal @set_hostname, @generated.shift
      assert_equal @upgrade_system_packages, @generated.shift
      assert_equal @install_essential_tools, @generated.shift
      assert_equal @install_apache2, @generated.shift
      assert_equal @install_mysql_server, @generated.shift
      assert_equal @install_git, @generated.shift
      assert_equal @install_core_ruby, @generated.shift
      assert_equal @install_ruby_mysql, @generated.shift
      assert_equal @install_rubygems, @generated.shift
      assert_equal @install_rails, @generated.shift
      assert_equal @install_passenger, @generated.shift
    end
  end
end 