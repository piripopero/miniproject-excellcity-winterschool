#!/bin/bash

set -e

# Definición de las variables necesarias
TUTORIAL_DATA_MODELS_CONTEXT="http://context:80/context.jsonld"
CONTEXT_BROKER="localhost:1026"
NGSILD_Tenant="excellcity"

# Función para mostrar mensajes en color
print_success() {
  echo -e "\033[1;32m$1\033[0m"  # Verde
}

print_error() {
  echo -e "\033[1;31m$1\033[0m"  # Rojo
}

print_info() {
  echo -e "\033[1;34m$1\033[0m"  # Azul
}

# Función para subir datos desde un archivo JSON y mostrar los resultados
upload_data() {
  DATA_TYPE=$1   # Tipo de datos, e.g., buildings, buildingspaces, etc.
  JSONL_FILE=$2  # Ruta del archivo JSON que contiene los datos

  # Comprobar si el archivo JSON existe antes de procesarlo
  if [[ ! -f "$JSONL_FILE" ]]; then
    print_error "✘ File not found for ${DATA_TYPE}: $JSONL_FILE"
    return 1  # Continuar con el siguiente archivo si no existe
  fi

  print_info "⏳ Uploading ${DATA_TYPE} data from $JSONL_FILE..."

  DATA=$(cat "$JSONL_FILE")

  # Usamos un archivo temporal para capturar la respuesta
  HTTP_RESPONSE=$(mktemp)

  # Ejecutar curl y capturar el código de respuesta HTTP
  HTTP_CODE=$(curl --location "http://${CONTEXT_BROKER}/ngsi-ld/v1/entityOperations/upsert" \
    --header "NGSILD-Tenant: ${NGSILD_Tenant}" \
    --header "Link: <${TUTORIAL_DATA_MODELS_CONTEXT}>; rel=\"http://www.w3.org/ns/json-ld#context\"; type=\"application/ld+json\"" \
    --header "Content-Type: application/json" \
    --data-raw "$DATA" \
    --write-out "%{http_code}" \
    --silent \
    --output "$HTTP_RESPONSE")

  # Verificar el código de respuesta
  if [ "$HTTP_CODE" -eq 201 ] || [ "$HTTP_CODE" -eq 204 ]; then
    print_success "✔ ${DATA_TYPE} data uploaded successfully! HTTP Status: $HTTP_CODE"

    # Verificar si la respuesta es un array JSON válido
    if jq -e . >/dev/null 2>&1 <<<"$(cat "$HTTP_RESPONSE")"; then
      # Mostrar los IDs de las entidades creadas si es un JSON válido
      print_success "Entities created/updated:"
      cat "$HTTP_RESPONSE" | jq '.[]' || print_info "No valid entities found."
    else
      print_info "No valid JSON response. Response body:"
      cat "$HTTP_RESPONSE"
    fi

  else
    print_error "✘ Error uploading ${DATA_TYPE} data. HTTP Status: $HTTP_CODE"
    echo "Response body:"
    cat "$HTTP_RESPONSE"  # Mostrar el cuerpo de la respuesta en caso de error
  fi

  # Limpiar el archivo temporal
  rm -f "$HTTP_RESPONSE"
}

# Subir los diferentes tipos de datos
upload_data "Buildings" "./import-data/buildings.json"
upload_data "BuildingSpaces" "./import-data/buildingspaces.json"
upload_data "Devices" "./import-data/devices.json"
upload_data "WeatherForecast" "./import-data/weatherforecast.json"
upload_data "WeatherObserved" "./import-data/weatherobserved.json"
