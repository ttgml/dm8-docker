FROM openeuler/openeuler:22.03 AS installer

RUN groupadd dinstall -g 2001 && \
    useradd -G dinstall -m -d /home/dmdba -s /bin/bash -u 2001 dmdba && \
    chmod 777 /tmp &&\
    yum install sudo -y && yum clean all
COPY DMInstall.bin /mnt/DMInstall.bin
COPY setup.xml /tmp/setup.xml
RUN sudo -u dmdba /mnt/DMInstall.bin -q /tmp/setup.xml

FROM openeuler/openeuler:22.03 
RUN groupadd dinstall -g 2001 && \
    useradd -G dinstall -m -d /home/dmdba -s /bin/bash -u 2001 dmdba && \
    chmod 777 /tmp && \
    yum install sudo -y && yum clean all 
COPY --from=installer /home/dmdba/ /home/dmdba/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
USER root
EXPOSE 5236
ENTRYPOINT [ "/entrypoint.sh" ]