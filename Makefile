include .env
export

# Run each recipe in a single shell (required for heredoc support)
.ONESHELL:

# Use 'docker compose' (v2 plugin) if available, otherwise fall back to 'docker-compose' (v1)
COMPOSE := $(shell docker compose version >/dev/null 2>&1 && echo "docker compose" || echo "docker-compose")

.PHONY: init up user

# Install Docker and Docker Compose via apt (Ubuntu)
init:
	@command -v docker >/dev/null 2>&1 || { \
		echo "Installing Docker..."; \
		sudo apt-get update -qq; \
		sudo apt-get install -y docker.io; \
		sudo usermod -aG docker $$USER; \
		echo "Docker installed. Re-login or run: newgrp docker"; \
	}
	@docker compose version >/dev/null 2>&1 || command -v docker-compose >/dev/null 2>&1 || { \
		echo "Installing Docker Compose..."; \
		sudo apt-get install -y docker-compose-plugin 2>/dev/null || sudo apt-get install -y docker-compose; \
	}
	@test -f .env || { \
		cp .env.example .env; \
		echo ".env created from .env.example — fill in the values before running 'make up'"; \
	}
	@echo "All dependencies are ready"

# Configure and start all services
up: _generate-element-config _generate-synapse-config _start

_generate-element-config:
	@echo "Generating element-config.json..."
	@cat > element-config.json <<- EOF
	{
	  "default_server_config": {
	    "m.homeserver": {
	      "base_url": "https://$(MATRIX_HOST)",
	      "server_name": "$(SERVER_NAME)"
	    }
	  },
	  "disable_custom_urls": true,
	  "disable_guests": true,
	  "brand": "$(ELEMENT_BRAND)"
	}
	EOF

_generate-synapse-config:
	@echo "Setting up Synapse config..."
	@mkdir -p data
	@if [ ! -f data/homeserver.yaml ]; then \
		echo "Generating homeserver.yaml..."; \
		docker run --rm \
			-v $(PWD)/data:/data \
			-e SYNAPSE_SERVER_NAME=$(SERVER_NAME) \
			-e SYNAPSE_REPORT_STATS=no \
			matrixdotorg/synapse:latest generate; \
	fi

_start:
	@echo "Starting services..."
	@$(COMPOSE) up -d
	@echo "Matrix is up"

# Add a new user (interactive). Optional: make user USERNAME=alice PASSWORD=secret ADMIN=yes
user:
ifdef USERNAME
	docker exec matrix-synapse register_new_matrix_user \
		-c /data/homeserver.yaml \
		-u "$(USERNAME)" \
		$(if $(PASSWORD),-p "$(PASSWORD)") \
		$(if $(filter yes,$(ADMIN)),--admin,--no-admin) \
		http://localhost:8008
else
	docker exec -it matrix-synapse register_new_matrix_user \
		-c /data/homeserver.yaml http://localhost:8008
endif