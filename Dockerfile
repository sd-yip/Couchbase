FROM couchbase:community-5.0.1

RUN apt-get update && apt-get install -y socat=1.7.3.1-1 && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN wget https://github.com/krallin/tini/releases/download/v0.19.0/tini && chmod +x tini

ENTRYPOINT ["/tini", "--", "/docker-entrypoint.sh"]
CMD ["couchbase-server"]
COPY docker-entrypoint.sh .
