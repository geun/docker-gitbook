FROM node:8.11.2
MAINTAINER Ken <ken@flui.ai>


RUN apt-get update && apt-get install -yq libgconf-2-4

# Install latest chrome dev package and fonts to support major charsets (Chinese, Japanese, Arabic, Hebrew, Thai and a few others)
# Note: this installs the necessary libs to make the bundled version of Chromium that Puppeteer
# installs, work.
RUN apt-get update && apt-get install -y wget --no-install-recommends \
    && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
    && apt-get update \
    && apt-get install -y google-chrome-unstable fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst ttf-freefont \
      --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get purge --auto-remove -y curl \
    && rm -rf /src/*.deb

# It's a good idea to use dumb-init to help prevent zombie chrome processes.
ADD https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 /usr/local/bin/dumb-init
RUN chmod +x /usr/local/bin/dumb-init

# Uncomment to skip the chromium download when installing puppeteer. If you do,
# you'll need to launch puppeteer with:
#     browser.launch({executablePath: 'google-chrome-unstable'})
# ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD true

# install calibre dependencies and gitbook-cli
RUN apt-get update && \
    apt-get install -y unzip calibre && \
    yarn global add gitbook-cli && \
    yarn global add svgexport && \
    apt-get clean && \
    rm -rf /var/cache/apt/* /var/lib/apt/lists/*

# install Arial fonts
RUN wget -P /tmp/raw_fonts https://github.com/billryan/algorithm-exercise/files/279471/arial.zip && \
    cd /tmp/raw_fonts && \
    unzip -o arial.zip && \
    mv -t /usr/share/fonts/truetype Arial*ttf && \
    rm arial.zip && \
    fc-cache -f -v

# add non-root user(workaround for docker)
# replace gid and uid with your currently $GID and $UID
#RUN useradd -m -g 100 -u 1000 gitbook
#USER gitbook

# install fonts Noto Sans CJK SC for Simplified Chinese
RUN wget -P /raw_fonts https://noto-website-2.storage.googleapis.com/pkgs/NotoSansCJKsc-hinted.zip && \
    cd /raw_fonts && \
    mkdir /usr/share/fonts/noto && \
    unzip -o NotoSansCJKsc-hinted.zip && \
    mv -t /usr/share/fonts/noto *-DemiLight.otf *-Bold.otf *-Black.otf && \
    rm -r /raw_fonts && \
    fc-cache -f -v

# install gitbook versions
RUN gitbook fetch latest

# Install puppeteer so it's available in the container.
RUN yarn add puppeteer

# Add user so we don't need --no-sandbox.
RUN groupadd -r pptruser && useradd -r -g pptruser -G audio,video pptruser \
    && mkdir -p /home/pptruser/Downloads \
    && chown -R pptruser:pptruser /home/pptruser \
    && chown -R pptruser:pptruser /node_modules

# Run everything after as non-privileged user.
USER pptruser


#
#ENV BOOKDIR /gitbook
#
#VOLUME $BOOKDIR
#
#EXPOSE 4000
#
#WORKDIR $BOOKDIR

CMD ["gitbook", "--help"]
