
CREATE TABLE IF NOT EXISTS posey.accounts (
    id INT,
    name VARCHAR(255),
    website VARCHAR(255),
    lat DECIMAL,
    long DECIMAL,
    primary_poc VARCHAR(255),
    sales_rep_id INT,
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS posey.orders (
    id INT,
    account_id INT,
    occurred_at TIMESTAMP,
    standard_qty INT,
    gloss_qty INT,
    poster_qty INT,
    total INT,
    standard_amt_usd DECIMAL(10,2),
    gloss_amt_usd DECIMAL(10,2),
    poster_amt_usd DECIMAL(10,2),
    total_amt_usd DECIMAL(10,2),
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS posey.region (
    id INT,
    name VARCHAR(100),
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS posey.sales_reps (
    id INT,
    name VARCHAR(255),
    region_id INT,
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS posey.web_events (
    id INT,
    account_id INT,
    occurred_at TIMESTAMP,
    channel VARCHAR(50),
    PRIMARY KEY (id)
);
