FROM alpine:3.16.0

RUN apk update && \
    apk add --no-cache \
    texlive-full=20220403.62885-r2 \
    make=4.3-r0
