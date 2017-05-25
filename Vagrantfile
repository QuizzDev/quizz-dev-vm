# -*- mode: ruby -*-
# vi: set ft=ruby :

box      = "ubuntu/trusty64"
hostname = "quizz.local"
ip       = "192.168.61.10"
ram      = "1024"


Vagrant.configure(2) do |config|
  config.vm.box = box
  config.vm.box_check_update = true
  config.vm.network "private_network", ip: ip
  config.vm.hostname = hostname
  config.hostsupdater.aliases = [
    "www." + hostname
  ]

  NFS_VERSION = 3
  NFS_OPTIONS = ['nolock,vers=3,udp']
  if OS.windows?
      puts "Vagrant launched from Windows."
  elsif OS.mac?
      puts "Vagrant launched from OSX."
  elsif OS.unix?
      redef_without_warning :NFS_OPTIONS, ['nolock']
      puts "Vagrant launched from Unix."
  elsif OS.linux?
      redef_without_warning :NFS_VERSION, 4
      redef_without_warning :NFS_OPTIONS, ['nolock']
      puts "Vagrant launched from Linux."
  else
      puts "Vagrant launched from unknown platform."
  end

  config.vm.synced_folder "../phpcs", "/home/phpcs"
  config.vm.synced_folder "../quizz-service", "/var/www/quizz.local",
      type: "nfs",
      :nfs => true,
      :nfs_version => NFS_VERSION,
      :mount_options => NFS_OPTIONS

  config.vm.provider "virtualbox" do |vb|
     vb.memory = ram
  end

  config.vm.provision "shell", inline: <<-SHELL

    locale-gen UTF-8

        # php7 repository
        sudo LC_ALL=en_US.UTF-8 add-apt-repository ppa:ondrej/php

        # reload packages lists
        sudo apt-get update -y

        # git
        sudo apt-get install git -y

        ### quizz
        sudo apt-get install python-software-properties ppa-purge -y

        sudo apt-get purge php5-common -y
        sudo apt-get install php7.0 php7.0-fpm php7.0-mysql php7.0-zip php7.0-xml -y

        # run php-fpm as vagrant
        sed -i 's/^user = www-data$/user = vagrant/' /etc/php/7.0/fpm/pool.d/www.conf
        sed -i 's/^group = www-data$/group = vagrant/' /etc/php/7.0/fpm/pool.d/www.conf
        sed -i 's/^listen.owner = www-data$/listen.owner = vagrant/' /etc/php/7.0/fpm/pool.d/www.conf
        sed -i 's/^listen.group = www-data$/listen.group = vagrant/' /etc/php/7.0/fpm/pool.d/www.conf
        sed -i 's/^pm.max_children = .*$/pm.max_children = 51/' /etc/php/7.0/fpm/pool.d/www.conf
        chown -R vagrant:vagrant /run/php/php7.0-fpm.sock

        # xdebug
        sudo apt-get install -y php7.0-dev php-xdebug
        sudo cp -f /vagrant/config/etc/php/mod-available/xdebug.ini /etc/php/7.0/mods-available/xdebug.ini

        # gd lib for image manipulation
        sudo apt-get install php7.0-gd -y

        # php libs required for rabbitmq
        sudo apt-get install php7.0-curl php7.0-mbstring php7.0-bcmath -y

        # composer
        curl -sS https://getcomposer.org/installer | php
        sudo mv composer.phar /usr/local/bin/composer

        # PHP CodeSniffer
        sudo cp -f /vagrant/config/git/hook-pre-commit /var/www/quizz.local/.git/hooks/pre-commit

        # mysql
        debconf-set-selections <<< 'mysql-server mysql-server/root_password password quizz'
        debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password quizz'

        sudo apt-get install mysql-server -y

        # # replace configuration
        sudo cp -f /vagrant/config/etc/mysql/my.cnf /etc/mysql/my.cnf
        sudo service mysql restart

        # # allow to login
        mysql -u root -pquizz -D mysql < /vagrant/scripts/mysql_user_config.sql

        # # create quizz database
        mysql -u root -pquizz < /vagrant/scripts/mysql_database_create.sql

        # # create quizz database
        mysql -u root -pquizz -D quizz < /var/www/quizz.local/sql/latest.sql

        ### install zip
        sudo apt-get install -y zip

        # java
        sudo apt-get install -y openjdk-7-jre-headless

        # ant
        sudo apt-get install -y ant

        # nginx
        sudo apt-get install -y nginx
        rm -f /etc/nginx/sites-enabled/default
        cp /vagrant/config/etc/nginx/sites-enabled/* /etc/nginx/sites-enabled/.
        mkdir -p /etc/nginx/ssl
        cp -f /vagrant/certs/rootCA.pem /vagrant/certs/quizz.crt /vagrant/certs/quizz.key /etc/nginx/ssl
        sed -i 's/^user www-data;$/user vagrant;/' /etc/nginx/nginx.conf
        sed -i 's/^worker_processes.*$/worker_processes 1;/' /etc/nginx/nginx.conf
        mkdir -p /var/log/nginx
        chown -R vagrant:vagrant /var/log/nginx
        service nginx restart

        # add certificate to system
        cp /vagrant/certs/rootCA.pem /usr/local/share/ca-certificates/rootCA.crt
        update-ca-certificates --fresh

        # add github deploy key
        #cp /vagrant/config/ssh/config /vagrant/config/ssh/github-deploy-key /home/vagrant/.ssh/
        #touch /home/vagrant/.ssh/known_hosts
        #ssh-keyscan -t rsa,dsa github.com 2>&1 | sort -u - /home/vagrant/.ssh/known_hosts > /home/vagrant/.ssh/tmp_hosts
        #mv /home/vagrant/.ssh/tmp_hosts /home/vagrant/.ssh/known_hosts
        #chown -R vagrant:vagrant /home/vagrant/.ssh
        #chmod 0400 /home/vagrant/.ssh/github-deploy-key

        # packages cleanup
        sudo apt-get --purge autoremove -y

        # disable php-xdebug by default
        /vagrant/scripts/quizz_debug.sh

        # settings for showing country in the prompt
        su - vagrant -c 'echo "source /vagrant/config/bash_aliases" >> ~/.bashrc'

        # installing
        sudo apt-get install php7.0-intl -y
        sudo /usr/share/locales/install-language-pack de_DE

        # configure the quizz-service app
        su - vagrant -c 'cd /var/www/quizz.local && composer install -q --no-interaction'
        su - vagrant -c 'cd /var/www/quizz.local && php app/console assets:install --symlink'
        ln -sfT /dev/shm/quizz/logs /var/log/quizz


  SHELL
end

module OS
    def OS.windows?
        (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
    end

    def OS.mac?
        (/darwin/ =~ RUBY_PLATFORM) != nil
    end

    def OS.unix?
        !OS.windows?
    end

    def OS.linux?
        OS.unix? and not OS.mac?
    end
end

class Object
  def def_if_not_defined(const, value)
    mod = self.is_a?(Module) ? self : self.class
    mod.const_set(const, value) unless mod.const_defined?(const)
  end

  def redef_without_warning(const, value)
    mod = self.is_a?(Module) ? self : self.class
    mod.send(:remove_const, const) if mod.const_defined?(const)
    mod.const_set(const, value)
  end
end
