#
# GlassFish - Application Server
#

FROM miquelo/glassfish-4.1.1-debian:latest

COPY [ "prepare-jdk8.sh", "/tmp/setup/execute.sh" ]
RUN [ "sh", "/tmp/setup/execute.sh" ]

COPY [ "prepare-glassfish.sh", "/tmp/setup/execute.sh" ]
RUN [ "sh", "/tmp/setup/execute.sh" ]

COPY [ "clean-system.sh", "/tmp/setup/execute.sh" ]
RUN [ "sh", "/tmp/setup/execute.sh" ]

RUN [ "rm", "-r", "/tmp/setup" ]
CMD [ "supervisord", "-n" ]

