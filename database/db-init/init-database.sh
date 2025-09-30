#!/bin/bash
set -e

echo "========================================="
echo "INICIANDO CRIAÇÃO DE BANCOS DE DADOS"
echo "========================================="

# Espera o PostgreSQL iniciar completamente
until pg_isready -U "${POSTGRES_USER:-postgres}" -q; do
  echo "Aguardando PostgreSQL iniciar..."
  sleep 2
done

PGUSER="${POSTGRES_USER:-postgres}"
PGPASSWORD="${POSTGRES_PASSWORD:-}"
DB_NAMES="${POSTGRES_DB_NAMES:-}"

echo "Usuário: $PGUSER"
echo "Bancos solicitados: $DB_NAMES"

export PGUSER PGPASSWORD

if [ -z "$DB_NAMES" ]; then
  echo "⚠️  Variável POSTGRES_DB_NAMES não definida ou vazia. Nada a criar."
  exit 0
fi

# Conexão psql
PSQL="psql -v ON_ERROR_STOP=1 --username $PGUSER --no-password"

# Transformar DB_NAMES em array, separando por vírgula
IFS=',' read -ra DBS <<< "$DB_NAMES"

echo "Criando bancos: ${DBS[*]}"

for db in "${DBS[@]}"; do
  db_trimmed=$(echo "$db" | xargs)
  if [ -n "$db_trimmed" ]; then
    if $PSQL -lqt | cut -d \| -f 1 | grep -qw "$db_trimmed"; then
      echo "✓ Banco '$db_trimmed' já existe. Pulando..."
    else
      echo "→ Criando banco '$db_trimmed'..."
      $PSQL -c "CREATE DATABASE \"$db_trimmed\";"
      echo "✓ Banco '$db_trimmed' criado com sucesso!"
    fi
  fi
done

echo "========================================="
echo "✓ Todos bancos criados/verificados!"
echo "========================================="