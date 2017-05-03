#
# GlassFish - Apache 2 load balancer
#

FROM miquelo/glassfish-4.1.1-debian:latest

COPY [ "prepare-sudo.sh", "/tmp/setup/execute.sh" ]
RUN [ "sh", "/tmp/setup/execute.sh" ]

COPY [ "prepare-apache.sh", "/tmp/setup/execute.sh" ]
COPY [ "workers.py", "/tmp/setup/workers.py" ]
RUN [ "sh", "/tmp/setup/execute.sh" ]

COPY [ "prepare-python3.sh", "/tmp/setup/execute.sh" ]
RUN [ "sh", "/tmp/setup/execute.sh" ]

COPY [ "clean-system.sh", "/tmp/setup/execute.sh" ]
RUN [ "sh", "/tmp/setup/execute.sh" ]

RUN [ "rm", "-r", "/tmp/setup" ]
CMD [ "supervisord", "-n" ]

