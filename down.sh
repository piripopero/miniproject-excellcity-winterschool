#!/bin/bash

set -e

deleteVolumes=false

# Procesar flags de línea de comandos
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --clean)
      deleteVolumes=true
      shift
      ;;
    -*|--*)
      echo "Usage: down-sh [--clean]"
      exit 1
      ;;
    *)
      break
      ;;
  esac
done

dockerCmd="docker compose"
if (( $# == 2 )); then
    dockerCmd="docker-compose"
fi

stoppingContainers () {
  echo "Stopping and removing containers using Docker Compose..."
  if [ "$deleteVolumes" = true ]; then
    echo -e "\033[0;31mRemoving Docker volumes. Warning: Any data not mapped to a local directory will be lost.\033[0m"
    
    # Confirmación del usuario
    read -p $'\033[0;31mAre you sure you want to delete the volumes? This will result in data loss if the volumes are not mapped. Type \'y\' to continue: \033[0m' confirm
    if [[ $confirm != "y" ]]; then
      echo "Operation aborted. Volumes were not deleted."
      exit 1
    fi
    
    echo "Removing containers and volumes"
    ${dockerCmd} down -v
  else
    echo "Removing containers without deleting volumes"
    ${dockerCmd} down
  fi
}

# Ejecutar la función para detener contenedores y eliminar volúmenes si corresponde
stoppingContainers