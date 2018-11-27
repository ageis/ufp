FROM python:3.7.1-stretch AS py3
ENV DEBIAN_FRONTEND noninteractive
RUN /bin/echo -e "deb http://httpredir.debian.org/debian stretch-backports main contrib non-free\n" >> /etc/apt/sources.list
RUN apt-get -qy update 

RUN apt-get -qy update && apt-get -qy install python3-dev python3-virtualenv python3-pytest virtualenvwrapper tree apt-utils && apt-get -qy -t stretch-backports dist-upgrade
RUN rm -rf /var/cache/apt/* /var/lib/apt/lists/*
RUN pip install -U setuptools virtualenvwrapper distro
ADD requirements/dev.txt /srv/dev.txt

ARG REQS=base
#COPY /etc/pip.conf ~/.config/pip/pip.con

RUN mkdir -p /srv/ufp /venv
ENV WORKON_HOME /venv
ENV PROJECT_HOME /srv


RUN /bin/bash -c 'source /usr/share/virtualenvwrapper/virtualenvwrapper.sh && mkvirtualenv -p /usr/bin/python3 -a /srv/ufp -r /srv/dev.txt py3'
ADD . /srv/ufp 
WORKDIR /srv/ufp

ENV PYTHON_EGG_DIR /tmp

RUN tree /srv/ufp

RUN python3 setup.py build
RUN python3 setup.py egg_info -Db '' sdist bdist_egg
RUN python3 setup.py install
RUN python3 runtests.py
CMD ["/venv/py3/bin/python3", "-m", "ufp"]
