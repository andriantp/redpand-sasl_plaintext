.PHONY: \
	up-redpanda \
	down-redpanda \
	up-console \
	down-console \
	ps \
	logs-redpanda \
	clean \
	prune \
	health \
	version \
	create-user \
	test-topic \
	list-topics

REDPANDA_COMPOSE=docker/sasl.docker-compose.yml

BROKER=localhost:19092
USER=admin
PASSWORD=admin-password
MECHANISM=SCRAM-SHA-256

# ======================== Cleanup ========================

clean:
	@echo "🧹 Cleaning project data..."
	rm -rf docker/redpanda

prune:
	@echo "💣 Pruning Docker system (DANGEROUS)..."
	docker system prune -a -f

# ======================== Redpanda ========================

up-redpanda:
	@echo "🐳 Starting Redpanda..."
	mkdir -p docker/redpanda
	chmod -R 777 docker/redpanda
	docker compose -f $(REDPANDA_COMPOSE) up --force-recreate -d redpanda
	@echo "✅ Redpanda started"

down-redpanda:
	@echo "🛑 Stopping Redpanda..."
	docker compose -f $(REDPANDA_COMPOSE) stop redpanda
	@echo "✅ Redpanda stopped"

up-console:
	@echo "🐳 Starting Redpanda Console..."
	docker compose -f $(REDPANDA_COMPOSE) up --force-recreate -d console
	@echo "✅ Redpanda Console started"

down-console:
	@echo "🛑 Stopping Redpanda Console..."
	docker compose -f $(REDPANDA_COMPOSE) stop console
	@echo "✅ Console stopped"

# ======================== Monitoring ========================

ps:
	@echo "📋 Container status:"
	docker ps -a --filter "name=redpanda"

logs-redpanda:
	@echo "📝 Redpanda logs:"
	docker compose -f $(REDPANDA_COMPOSE) logs -f redpanda

# ======================== Auth ========================

create-user:
	@echo "👤 Creating SASL user..."
	docker exec -it redpanda rpk security user create $(USER) \
		--password '$(PASSWORD)' \
		--mechanism $(MECHANISM)

# ======================== Health ========================

health:
	@echo "⏳ Checking Redpanda health..."
	rpk cluster info \
		--brokers $(BROKER) \
		--user $(USER) \
		--password $(PASSWORD) \
		--sasl-mechanism $(MECHANISM)

version:
	@echo "📦 Redpanda version:"
	rpk version

# ======================== Topics ========================

test-topic:
	@echo "🔍 Creating test topic..."
	rpk topic create test-topic \
		--brokers $(BROKER) \
		--user $(USER) \
		--password $(PASSWORD) \
		--sasl-mechanism $(MECHANISM)

list-topics:
	@echo "📋 Listing topics..."
	rpk topic list \
		--brokers $(BROKER) \
		--user $(USER) \
		--password $(PASSWORD) \
		--sasl-mechanism $(MECHANISM)