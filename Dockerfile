# ---------------------------------------------------------------------------
# Builder stage: the -dev image has root, a shell and a compiler, so install the
# extra plugin gems here into one relocatable prefix.
# ---------------------------------------------------------------------------
FROM cgr.dev/brightfin.com/fluentd:1.18-dev AS builder

USER root

ENV GEM_HOME=/opt/gems
ENV PATH="/opt/gems/bin:$PATH"

COPY /plugins /plugins

# The base image already bundles elasticsearch, opensearch, s3, cloudwatch-logs,
# kubernetes_metadata, multi-format-parser and prometheus. Add what it lacks, and
# pin the elasticsearch client to 8.x (see es-pin.rb).
# Optional build secret `extra_ca`: a PEM to trust in addition to the system CAs,
# for builds behind a TLS-intercepting proxy (e.g. Netskope). Not needed in CI:
#   docker build --secret id=extra_ca,src=netskope-ca.pem .
RUN --mount=type=secret,id=extra_ca,required=false \
    if [ -s /run/secrets/extra_ca ]; then \
        cat /etc/ssl/certs/ca-certificates.crt /run/secrets/extra_ca > /tmp/ca-bundle.crt; \
        export SSL_CERT_FILE=/tmp/ca-bundle.crt; \
    fi \
    && gem install --no-document elasticsearch -v 8.18.1 \
    && gem install --no-document fluent-plugin-record-reformer \
    && gem install --no-document fluent-plugin-slack \
    && gem install --no-document fluent-plugin-grep \
    # Build and install the custom Fluentd plugin
    && cd /plugins/fluent-plugin-rollbar && git init && git add . \
    && gem build fluent-plugin-rollbar \
    && gem install --no-document ./fluent-plugin-rollbar-0.1.0.gem \
    && rm -rf /opt/gems/cache/*.gem

# ---------------------------------------------------------------------------
# Final stage: the hardened Fluentd image just receives the prebuilt gems.
# ---------------------------------------------------------------------------
FROM cgr.dev/brightfin.com/fluentd:1.18

COPY --from=builder /opt/gems /opt/gems
COPY es-pin.rb /opt/es-pin.rb

# /opt/gems first so its elasticsearch 8.x wins; the base gem dir stays on the
# path for everything else the image bundles.
ENV GEM_PATH="/opt/gems:/usr/lib/ruby/gems/3.4.0"
ENV RUBYOPT="-r/opt/es-pin.rb"

# Sanity-check that Fluentd can see the installed plugins at build time.
RUN ["/usr/bin/fluent-gem", "list"]
