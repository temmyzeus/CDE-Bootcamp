# Setup
1. Create a `.env` file containing the following variables

```bash
POSTGRES_USER="<user_name>"
POSTGRES_PASSWORD="<password>"
```

2. Run the bash script `docker-setup.sh`

```bash
chmod u+x docker-setup.sh
./docker-setup.sh
```

3. Connect to Postgres Using credentials in `.env` file, `localhost` as hostname and port `25432` to view your data
