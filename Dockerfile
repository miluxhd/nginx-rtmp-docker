##############################
# Build the NGINX-build image.
FROM ubuntu:16.04

# Build dependencies.
RUN apt update && apt install -y  supervisor  libopus-dev librtmp-dev  libtheora-dev libvpx-dev  libwebp-dev libx264-dev libx265-dev libssl-dev nasm yasm  libass-dev  libfdk-aac-dev  libmp3lame-ocaml-dev libvorbis-dev wget libpcre3 libpcre3-dev

# Get nginx source.
RUN cd /tmp && \
  wget https://nginx.org/download/nginx-1.14.1.tar.gz && \
  tar xzf nginx-1.14.1.tar.gz && \
  rm nginx-1.14.1.tar.gz

# Get nginx-rtmp module.
RUN cd /tmp && \
  wget https://github.com/arut/nginx-rtmp-module/archive/v1.2.1.tar.gz && \
  tar zxf v1.2.1.tar.gz && rm v1.2.1.tar.gz

# Compile nginx with nginx-rtmp module.
RUN cd /tmp/nginx-1.14.1 && \
  ./configure \
  --prefix=/usr/local/nginx \
  --add-module=/tmp/nginx-rtmp-module-1.2.1 \
  --conf-path=/etc/nginx/nginx.conf \
  --with-threads \
  --with-file-aio \
  --with-http_ssl_module \
  --error-log-path=/var/log/nginx/error.log \
  --http-log-path=/var/log/nginx/access.log \
  --with-debug && \
  cd /tmp/nginx-1.14.1 && make && make install

###############################
# Get FFmpeg source.
RUN cd /tmp/ && \
  wget http://ffmpeg.org/releases/ffmpeg-4.1.tar.gz && \
  tar zxf ffmpeg-4.1.tar.gz && rm ffmpeg-4.1.tar.gz

# Compile ffmpeg.
RUN cd /tmp/ffmpeg-4.1 && \
  ./configure \
  --prefix=/usr/local/ffmpeg \
  --enable-version3 \
  --enable-gpl \
  --enable-nonfree \
  --enable-small \
  --enable-libmp3lame \
  --enable-libx264 \
  --enable-libx265 \
  --enable-libvpx \
  --enable-libtheora \
  --enable-libvorbis \
  --enable-libopus \
  --enable-libfdk-aac \
  --enable-libass \
  --enable-libwebp \
  --enable-librtmp \
  --enable-postproc \
  --enable-avresample \
  --enable-libfreetype \
  --enable-openssl \
  --disable-debug \
  --disable-doc \
  --disable-ffplay \
  --extra-libs="-lpthread -lm" && \
  make && make install && make distclean

# Cleanup.
RUN rm -rf /var/cache/* /tmp/*

# Add NGINX config and static files.
ADD nginx.conf /etc/nginx/nginx.conf
RUN mkdir -p /data 
ADD static /var/www/html/static

# Add Supervisord configurations
ADD start-supervisor.sh /opt/start-supervisor.sh
RUN chmod +x /opt/start-supervisor.sh
RUN sed -i 's/^\(\[supervisord\]\)$/\1\nnodaemon=true/' /etc/supervisor/supervisord.conf
ADD supervisor.conf /etc/supervisor/conf.d/nginx.conf

# Create nginx directories
RUN chown www-data:www-data /data 
RUN chown www-data:www-data /usr/local/nginx/
RUN chown www-data:www-data /var/log/nginx 


EXPOSE 1935
EXPOSE 8080

ENTRYPOINT ["/opt/start-supervisor.sh"]

