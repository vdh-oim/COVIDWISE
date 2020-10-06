## Referring where the multiple docker files are sourced

# https://hub.docker.com/layers/openjdk/library/openjdk/8u212-jdk-alpine3.9/images/sha256-210ecd2595991799526a62a7099718b149e3bbefdb49764cc2a450048e0dd4c0?context=explore

FROM openjdk:8u212-jdk-alpine3.9

MAINTAINER https://github.com/rasekar2000/alp-openjdk-android-sdk-gradle

# Suggestion for fixing `AAPT2 failing to merge resources on Docker` compilation Error
# https://stackoverflow.com/a/49936412 

# https://github.com/Docker-Hub-frolvlad/docker-alpine-glibc/blob/master/Dockerfile

ENV LANG=C.UTF-8

# Here we install GNU libc (aka glibc) and set C.UTF-8 locale as default.

RUN ALPINE_GLIBC_BASE_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" && \
    ALPINE_GLIBC_PACKAGE_VERSION="2.31-r0" && \
    ALPINE_GLIBC_BASE_PACKAGE_FILENAME="glibc-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_BIN_PACKAGE_FILENAME="glibc-bin-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_I18N_PACKAGE_FILENAME="glibc-i18n-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    apk add --no-cache --virtual=.build-dependencies wget ca-certificates && \
    echo \
        "-----BEGIN PUBLIC KEY-----\
        MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApZ2u1KJKUu/fW4A25y9m\
        y70AGEa/J3Wi5ibNVGNn1gT1r0VfgeWd0pUybS4UmcHdiNzxJPgoWQhV2SSW1JYu\
        tOqKZF5QSN6X937PTUpNBjUvLtTQ1ve1fp39uf/lEXPpFpOPL88LKnDBgbh7wkCp\
        m2KzLVGChf83MS0ShL6G9EQIAUxLm99VpgRjwqTQ/KfzGtpke1wqws4au0Ab4qPY\
        KXvMLSPLUp7cfulWvhmZSegr5AdhNw5KNizPqCJT8ZrGvgHypXyiFvvAH5YRtSsc\
        Zvo9GI2e2MaZyo9/lvb+LbLEJZKEQckqRj4P26gmASrZEPStwc+yqy1ShHLA0j6m\
        1QIDAQAB\
        -----END PUBLIC KEY-----" | sed 's/   */\n/g' > "/etc/apk/keys/sgerrand.rsa.pub" && \
    wget \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    apk add --no-cache \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    \
    rm "/etc/apk/keys/sgerrand.rsa.pub" && \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "$LANG" || true && \
    echo "export LANG=$LANG" > /etc/profile.d/locale.sh && \
    \
    apk del glibc-i18n && \
    \
    rm "/root/.wget-hsts" && \
    apk del .build-dependencies && \
    rm \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME"


# https://github.com/alvr/alpine-android/blob/master/android-base/Dockerfile 

ENV SDK_TOOLS "4333796"
ENV ANDROID_HOME "/opt/sdk"
ENV PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools

# Install required dependencies
RUN apk add --no-cache bash git unzip wget && \
    apk add --virtual .rundeps $runDeps && \
    rm -rf /tmp/* && \
    rm -rf /var/cache/apk/*

# Download and extract Android Tools
RUN wget -q https://dl.google.com/android/repository/sdk-tools-linux-${SDK_TOOLS}.zip -O /tmp/tools.zip && \
    mkdir -p ${ANDROID_HOME} && \
    unzip -qq /tmp/tools.zip -d ${ANDROID_HOME} && \
    rm -v /tmp/tools.zip

# Install SDK Packages
RUN mkdir -p ~/.android/ && touch ~/.android/repositories.cfg && \
    yes | ${ANDROID_HOME}/tools/bin/sdkmanager "--licenses" && \
    ${ANDROID_HOME}/tools/bin/sdkmanager "platform-tools" "extras;android;m2repository" "extras;google;m2repository" "extras;google;instantapps" && \    
    ${ANDROID_HOME}/tools/bin/sdkmanager "--update"

WORKDIR /home/android

# https://github.com/alvr/alpine-android/blob/master/android-28/Dockerfile 

ENV BUILD_TOOLS "28.0.3"
ENV TARGET_SDK "28"

# Install SDK Packages
RUN ${ANDROID_HOME}/tools/bin/sdkmanager "build-tools;${BUILD_TOOLS}" "platforms;android-${TARGET_SDK}"


# https://hub.docker.com/r/cosmomill/alpine-gradle/dockerfile
## with version , SHA change .

#CMD ["gradle"]

ENV GRADLE_HOME /opt/gradle
#ENV GRADLE_VERSION 6.0
#ARG GRADLE_DOWNLOAD_SHA256=5a3578b9f0bb162f5e08cf119f447dfb8fa950cedebb4d2a977e912a11a74b91

# https://gradle.org/release-checksums/
ENV GRADLE_VERSION 5.4.1
ARG GRADLE_DOWNLOAD_SHA256=7bdbad1e4f54f13c8a78abc00c26d44dd8709d4aedb704d913fb1bb78ac025dc

RUN set -o errexit -o nounset \
    && echo "Installing dependencies" \
    && apk add --no-cache \
        bash \
        libstdc++ \
    \
    && echo "Installing build dependencies" \
    && apk add --no-cache --virtual .build-deps \
        ca-certificates \
        openssl \
        unzip \
    \
    && echo "Downloading Gradle" \
    && wget -O gradle.zip "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" \
    \
    && echo "Checking download hash" \
    && echo "${GRADLE_DOWNLOAD_SHA256} *gradle.zip" | sha256sum -c - \
    \
    && echo "Installing Gradle" \
    && unzip gradle.zip \
    && rm gradle.zip \
    && mkdir -p /opt \
    && mv "gradle-${GRADLE_VERSION}" "${GRADLE_HOME}/" \
    && ln -s "${GRADLE_HOME}/bin/gradle" /usr/bin/gradle \
    \
    && apk del .build-deps \
    \
    && echo "Adding gradle user and group" \
    && addgroup -S -g 1000 gradle \
    && adduser -D -S -G gradle -u 1000 -s /bin/ash gradle \
    && mkdir /home/gradle/.gradle \
    && chown -R gradle:gradle /home/gradle

# Create Gradle volume
VOLUME "/home/gradle/.gradle"
WORKDIR /home/gradle

RUN set -o errexit -o nounset \
    && echo "Testing Gradle installation" \
    && gradle --version

CMD ["tail", "-f", "/dev/null"]  

# ./gradlew clean assembleDebug

