
FROM nginx:1.27-alpine-slim 

ARG BUILD_SHA=local
LABEL org.opencontainers.image.revision="${BUILD_SHA}"

RUN addgroup -S appgroup \
    && adduser -S -D -H -G appgroup appuser \
    && mkdir -p /tmp/client_temp /tmp/proxy_temp \
                 /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp \
    && chown -R appuser:appgroup /tmp

COPY nginx.conf /etc/nginx/nginx.conf
COPY index.html /usr/share/nginx/html/index.html

RUN chown -R appuser:appgroup /usr/share/nginx/html \
    && sed -i "s/BUILD_ID_PLACEHOLDER/${BUILD_SHA}/g" \
       /usr/share/nginx/html/index.html 


USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1

