
MiniProject powered by FIWARE
========================================================


This document  outlines the steps to deploy the scenario locally using a script that automates the deployment and configuration of the necessary components. These components are defined within the docker-compose.yml file and are essential for setting up the environment for the scenario.

This file `deploy_linux` is designed to stop running Docker containers labeled with "org.fiware=excellcity", optionally delete associated Docker volumes, and set up FIWARE services such as Orion-LD, IoT-Agent, MongoDB, TimescaleDB, and Mintaka.

## Prerequisites
- Docker and Docker Compose must be installed on your system.
- The `docker-compose.yml` file should be present in the same directory as the script.
- A `.env` file with appropriate environment variables should also be present.

## Usage

### 1. Basic Execution

To execute the script without deleting any Docker volumes, run the following command in your terminal:

```bash
./deploy_linux
```


### 2. Clean Execution with Volume Removal

If you want to delete the Docker volumes associated with the containers (this will result in data loss unless the volumes have been mapped to a local directory) before running again, you can run the script with the `--clean` flag:

```bash
./deploy_linux --clean
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
4. Adds appropriate MongoDB indexes for Orion and IoT-Agent.
5. Waits for each service to be healthy before proceeding.

## Example Output

```
Starting containers: Orion, IoT-Agent, a linked data Context, a TimescaleDB, and a MongoDB database.
- Orion is the context broker
- IoT-Agent is configured for the JSON Protocol
...
Orion is now running and exposed on localhost
```

## Notes

- The script will wait for all components to be ready (i.e., their Docker health status turns to "healthy") before proceeding.
- Make sure the `.env` file is properly configured for your environment.

