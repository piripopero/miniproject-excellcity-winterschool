MiniProject powered by FIWARE
========================================================

This document outlines the steps to deploy the scenario locally using a script that automates the deployment and configuration of the necessary components. These components are defined within the docker-compose.yml file and are essential for setting up the environment for the scenario.

This file `deploy.sh` is designed to stop running Docker containers labeled with "org.fiware=excellcity", optionally delete associated Docker volumes, and set up FIWARE services such as Orion-LD, IoT-Agent, MongoDB, TimescaleDB, Mintaka, Node-RED, Mosquitto, and an Apache server.

## Prerequisites
- Docker and Docker Compose must be installed on your system.
- The `docker-compose.yml` file should be present in the same directory as the script.
- A `.env` file with appropriate environment variables should also be present.
- JSON files with entity data to be imported (e.g., buildings.json, buildingspaces.json, devices.json, etc.) should be available. Ensure the paths to these files are correctly set in the script.

## Usage

### 1. Basic Execution

To execute the script without deleting any Docker volumes, run the following command in your terminal. Ensure that the file has executable permissions (chmod +x file)

```bash
./deploy.sh
```

### 2. Clean Execution with Volume Removal

If you want to delete the Docker volumes associated with the containers (this will result in data loss unless the volumes have been mapped to a local directory) before running again, you can run the script with the `--clean` flag. Ensure that the file has executable permissions (chmod +x file):

```bash
./deploy.sh --clean
```

When using the `--clean` option, the script will:
- Stop and remove all containers with the label `org.fiware=excellcity`.
- Prompt you to confirm whether you want to delete the associated Docker volumes.
- **Important**: Deleting the volumes will result in the loss of any data not mapped to a local directory.

### 3. Confirmation for Volume Deletion

If you run the script with the `--clean` flag, you will see a warning message in red:

```
Removing Docker volumes. Warning: Any data not mapped to a local directory will be lost.
```

To proceed with deleting the volumes, type `y` when prompted:

```
Are you sure you want to delete the volumes? This will result in data loss if not mapped. Type 'y' to continue: 
```

If you do not type `y`, the operation will be aborted and the volumes will not be deleted.

## What the Script Does

1. Stops and removes Docker containers with the label `org.fiware=excellcity`.
2. Optionally removes Docker volumes associated with those containers (if `--clean` is used and confirmed).
3. Sets up the following FIWARE components:
   - **Orion-LD** (Context Broker)
   - **IoT-Agent** (configured for the JSON protocol)
   - **MongoDB** (Database for Orion-LD and IoT-Agent)
   - **TimescaleDB** (for time-series data)
   - **Mintaka** (for linked data querying)
   - **Node-RED** (for integrating external APIs such as weather data and simulating IoT devices reporting via MQTT)
   - **Mosquitto** (an MQTT broker to handle messages from IoT devices)
   - **Apache (HTTP Server)** (to serve the `context.jsonld` file for linked data)
4. Adds appropriate MongoDB indexes for Orion and IoT-Agent.
5. Waits for each service to be healthy before proceeding.
6. **Imports Static Data**: Once all services are up and healthy, the script will import the static data defined in JSON files (e.g., buildings.json, buildingspaces.json, devices.json, etc.) to prepare the scenario with the necessary entities.g., buildings.json, buildingspaces.json, devices.json, etc.). You need to ensure the paths to these files are correctly specified in the script, and that the following environment variables are set:
   - **TUTORIAL_DATA_MODELS_CONTEXT**: The URL to the linked data context (e.g., `http://context:80/context.jsonld`).
   - **CONTEXT_BROKER**: The hostname and port for the Orion-LD Context Broker (e.g., `localhost:1026`).
   - **NGSILD_Tenant**: The tenant ID to be used (e.g., `excellcity`).
   - These variables are used by the import script to push the data into the Context Broker.

## Example Output

```
Starting containers: Orion, IoT-Agent, a linked data Context, a TimescaleDB, a MongoDB database, Node-RED, Mosquitto, and an Apache server.
- Orion is the context broker
- IoT-Agent is configured for the JSON Protocol
- Node-RED is running for external API integration and IoT simulation
- Mosquitto is set up as the MQTT broker
...
Orion is now running and exposed on localhost
[INFO] Importing static data using import_static_data.sh
✔ Buildings data uploaded successfully! HTTP Status: 201
✔ BuildingSpaces data uploaded successfully! HTTP Status: 201
...
```

## Notes

- The script will wait for all components to be ready (i.e., their Docker health status turns to "healthy") before proceeding.
- Make sure the `.env` file is properly configured for your environment.
- Ensure that the JSON files containing the entity data are present and their paths are correctly set in the script to successfully import the scenario data.


## Stopping the Scenario

To stop the scenario and remove the running containers, you can use the `down.sh` script. This script will stop and remove all the Docker containers associated with the FIWARE scenario.

### 1. Basic Stop

To stop the containers without removing any associated Docker volumes, run the following command:

```bash
./down.sh
```

### 2. Stop with Volume Removal

If you also want to delete the Docker volumes associated with the containers (this will result in data loss unless the volumes have been mapped to a local directory), you can run the script with the `--clean` flag:

```bash
./down.sh --clean
```

Similar to the `deploy.sh` script, the `--clean` option will prompt you to confirm the deletion of the volumes:

```
Removing Docker volumes. Warning: Any data not mapped to a local directory will be lost.
Are you sure you want to delete the volumes? This will result in data loss if not mapped. Type 'y' to continue:
```

If you do not type `y`, the operation will be aborted and the volumes will not be deleted.
