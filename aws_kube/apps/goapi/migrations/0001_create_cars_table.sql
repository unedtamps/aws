CREATE TABLE IF NOT EXISTS cars (
    id          BIGSERIAL   PRIMARY KEY,
    brand       TEXT        NOT NULL,
    model       TEXT        NOT NULL,
    color       TEXT        NOT NULL,
    year        INTEGER     NOT NULL CHECK (year BETWEEN 1886 AND 2100),
    price_cents BIGINT      NOT NULL CHECK (price_cents >= 0),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT cars_brand_model_year_key UNIQUE (brand, model, year)
);