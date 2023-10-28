FROM ubuntu:mantic-20231011@sha256:4c32aacd0f7d1d3a29e82bee76f892ba9bb6a63f17f9327ca0d97c3d39b9b0ee

ARG SDRTRUNK_VERSION=v0.6.0-beta-2
ARG SDRTRUNK_OTHERVERSION=v0.6.0-beta2

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get -y --no-install-recommends install \
      ca-certificates \
      curl \
      unzip \
      s6 \
      doas \
      xmlstarlet \
      libusb-1.0-0 \
      nginx && \
    apt-get clean && rm -rf /tmp/setup /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN curl -fSsL https://www.sdrplay.com/software/SDRplay_RSP_API-Linux-3.07.1.run -o /tmp/sdrplay.run && \
    mkdir -p /tmp/sdrplay && \
    cd /tmp/sdrplay && \
    chmod a+x /tmp/sdrplay.run && \
    /tmp/sdrplay.run --tar xf && \
    ls -lah && \
    _apivers=$(sed -n 's/^VERS="\(.*\)"/\1/p' install_lib.sh) && \
    install -D -m644 sdrplay_license.txt /usr/share/licenses/libsdrplay/LICENSE && \
    install -D -m644 "x86_64/libsdrplay_api.so.${_apivers}" "/usr/local/lib/libsdrplay_api.so.${_apivers}" && \
    install -D -m755 x86_64/sdrplay_apiService /usr/bin/sdrplay_apiService && \
	cd /usr/local/lib && \
	ln -s "libsdrplay_api.so.${_apivers}" libsdrplay_api.so.2 && \
	ln -s "libsdrplay_api.so.${_apivers}" libsdrplay_api.so && \
    cd - && \
    rm -rf /tmp/sdrplay.run /tmp/sdrplay

RUN groupadd --system sdrtrunk && useradd --system --create-home --gid sdrtrunk sdrtrunk

RUN mkdir -p /home/sdrtrunk/app && chown -R sdrtrunk:sdrtrunk /home/sdrtrunk
WORKDIR /home/sdrtrunk/app

RUN curl -fSsL https://github.com/DSheirer/sdrtrunk/releases/download/${SDRTRUNK_VERSION}/sdr-trunk-linux-x86_64-${SDRTRUNK_OTHERVERSION}.zip -o /tmp/sdrtrunk.zip && \
    unzip /tmp/sdrtrunk.zip && \
    rm /tmp/sdrtrunk.zip && \
    mv sdr-trunk-linux-x86_64-${SDRTRUNK_OTHERVERSION}/* . && \
    rmdir sdr-trunk-linux-x86_64-${SDRTRUNK_OTHERVERSION}

COPY rootfs /

RUN chown -R sdrtrunk:sdrtrunk /home/sdrtrunk

ENV RDIO_SCANNER_APIKEY=
ENV RDIO_SCANNER_URL=

CMD ["/bin/s6-svscan", "/etc/s6"]
