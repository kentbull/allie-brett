FROM weboftrust/keri:1.2.0-dev10

SHELL ["/bin/bash", "-c"]

WORKDIR /keripy
COPY ./scripts /keripy/scripts
COPY ./heartnet-docker-workflow.sh /keripy/heartnet-docker-workflow.sh
COPY ./print-colors.sh /keripy/print-colors.sh

CMD ["/bin/bash"]
