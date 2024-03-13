FROM python:3.11.2-slim-bullseye AS builder

RUN apt update && apt upgrade --yes 

RUN useradd --create-home realsrdjus
USER realsrdjus
WORKDIR /home/realsrdjus

ENV VIRTUALENV=/home/realsrdjus/venv
RUN python3 -m venv $VIRTUALENV
ENV PATH="$VIRTUALENV/bin:$PATH"

COPY --chown=realsrdjus pyproject.toml constraints.txt ./
RUN python -m pip install --upgrade pip setuptools &&\
    python -m pip install --no-cache-dir -c constraints.txt ".[dev]"

COPY --chown=realsrdjus src/ src/
COPY --chown=realsrdjus test/ test/

RUN python -m pip install . -c constraints.txt && \
    python -m pytest test/unit/ && \
    python -m flake8 src/ && \
    python -m isort src/ --check && \
    python -m black src/ --check --quiet && \
    python -m pylint src/ --disable=C0114,C0116,R1705 && \
    python -m bandit -r src/ --quiet && \
    python -m pip wheel --wheel-dir dist/ . -c constraints.txt

FROM python:3.11.2-slim-bullseye

RUN apt update && apt upgrade --yes 

RUN useradd --create-home realsrdjus
USER realsrdjus
WORKDIR /home/realsrdjus

ENV VIRTUALENV=/home/realsrdjus/venv
RUN python3 -m venv $VIRTUALENV
ENV PATH="$VIRTUALENV/bin:$PATH"

COPY --from=builder /home/realsrdjus/dist/page_tracker*.whl /home/realsrdjus/

RUN python -m pip install --upgrade pip setuptools &&\
    python -m pip install --no-cache-dir page_tracker*.whl 

CMD ["flask", "--app", "page_tracker.app", "run", \
    "--host", "0.0.0.0", "--port", "5000"]
