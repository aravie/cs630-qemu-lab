# https://github.com/fcwu/docker-ubuntu-vnc-desktop
FROM dorowu/ubuntu-desktop-lxde-vnc
MAINTAINER Falcon wuzhangjin@gmail.com

RUN sed -i -e "s%/archive.ubuntu.com%/cn.archive.ubuntu.com%g" /etc/apt/sources.list

RUN apt-get -y update

RUN apt-get install -y vim cscope exuberant-ctags

RUN apt-get install -y gcc gdb binutils

RUN apt-get install -y qemu-kvm qemu-system-x86

RUN apt-get install -y qemu-user qemu-user-static

RUN apt-get install -y git ca-certificates

RUN apt-get install -y wget unzip bc

RUN apt-get install -y ruby
RUN gem sources -r http://rubygems.org/
RUN gem sources -r https://rubygems.org/
RUN gem sources -a https://ruby.taobao.org/

RUN gem install showterm

RUN apt-get install -y chromium-browser

# Allow ubuntu user use sudo without password
ADD sudoers.d/ubuntu /etc/sudoers.d/
RUN chmod 440 /etc/sudoers.d/ubuntu

# Add shortcuts on Desktop
ADD lab.desktop /
ADD help.desktop /
ADD demo.desktop /

# Add lab-name
ADD lab-name /

# Tune the screen size
ADD supervisord.conf /etc/supervisor/conf.d/

ADD startup.sh /

WORKDIR /cs630-qemu-lab/

EXPOSE 6080
EXPOSE 5900
EXPOSE 22

ENTRYPOINT ["/startup.sh"]
