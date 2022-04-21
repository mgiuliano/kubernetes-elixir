FROM elixir:1.13

ENV LANG=en_GB.UTF-8 \
    LANGUAGE=en_GB:en \
    LC_ALL=en_GB.UTF-8

WORKDIR /opt/build

COPY . .

RUN apt-get update \
    && apt-get install -y vim locales \
    && sed -i -e 's/# en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen \
    && /opt/build/bin/build

FROM elixir:1.13-slim

RUN addgroup --gid 1000 appuser \
    && adduser --system --uid 1000 --ingroup appuser --home /opt/app appuser

WORKDIR /opt/app

COPY --from=0 /opt/build/rel/artifacts .

RUN tar xzf hello.tar.gz \
    && rm -f hello.tar.gz \
    && chown -R appuser:appuser /opt/app

#USER appuser

CMD ["/opt/app/bin/hello", "start"]
