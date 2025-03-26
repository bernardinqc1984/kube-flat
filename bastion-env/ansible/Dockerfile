#FROM fedora
FROM rockylinux:9.0

ENV ANSIBLE_VERSION=2.16.14
#ENV PIP_ROOT_USER_ACTION=ignore
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

WORKDIR /opt/ansible

RUN dnf check-update; \
    dnf -y update; \
    dnf install -y gcc libffi-devel python3 python3-pyyaml epel-release ansible-core; \
    dnf install -y python3-pip python3-pip-wheel openssh-clients openssh-server; \
    #dnf install -y python39-pip python39-pip-wheel openssh-clients; \
    dnf clean all

RUN pip3 install --upgrade --user pip; \
    python3 -m pip install --upgrade --user pycrypto cryptography; \
    #python3 -m pip install --user ansible; \
    python3 -m pip install pyvcloud lxml requests; \
    python3 -m pip install openshift kubernetes; \
    ansible-galaxy collection install kubernetes.core ansible.posix community.crypto

COPY id_rsa /root/.ssh/
COPY id_rsa.pub /root/.ssh/
RUN chmod 0600 -R /root/.ssh/
RUN eval $(ssh-agent -s); \
    ssh-add ; \
    ssh-add -l


ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["--version"]
