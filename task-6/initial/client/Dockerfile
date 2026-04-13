FROM alpine:3.19
RUN apk add --no-cache wget
WORKDIR /app
COPY run_job.sh .
RUN chmod +x run_job.sh
ENTRYPOINT ["/bin/sh", "/app/run_job.sh"]
