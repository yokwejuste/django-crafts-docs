FROM python:3.11-slim

WORKDIR /docs

COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

COPY pyproject.toml uv.lock ./

RUN uv sync --frozen

COPY . .

RUN uv run zensical build

EXPOSE 3000

CMD ["uv", "run", "zensical", "serve", "--dev-addr", "0.0.0.0:3000"]
