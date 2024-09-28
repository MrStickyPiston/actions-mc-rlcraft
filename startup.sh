#!/bin/bash
# Clone the repository
git clone https://${GIT_USER}:${GIT_TOKEN}@github.com/${GIT_USER}/${GIT_REPO}.git /minecraft/data
git config --global --add safe.directory /minecraft/data
git config --global user.name "Server Progress"
git config --global user.email "mr.sticky.piston@gmail.com"

# Check if the server jar exists
if [ ! -f "./minecraft_server.jar" ]; then
  echo "Error: File minecraft_server.jar does not exist."
  exit 1
fi

echo "Found server jar"

# Download and set up Playit tool
curl -L -o playit-linux-amd64 https://github.com/playit-cloud/playit-agent/releases/latest/download/playit-linux-amd64
chmod +x ./playit-linux-amd64

# Server config
echo 'eula=true' > eula.txt

# Set permissions for the files
chmod -R 777 .

# Start the Playit tool in the background
./playit-linux-amd64 --secret ${playit_docker_key} --platform_docker > logs/playit.log &

# Start Minecraft server in a 'screen' session
echo "Starting minecraft server..."
screen -dmS minecraft sh -c 'java -Xmx12G -Xms2G -jar minecraft_server.jar nogui > ../minecraft.log'

echo "Waiting for minecraft server log..."
while [ ! -f ../minecraft.log ]; do sleep 1; done
tail -f ../minecraft.log &

# Monitor server status in a loop
START_TIME=$(date +%s)

while true; do
  CURRENT_TIME=$(date +%s)
  ELAPSED_TIME=$((CURRENT_TIME - START_TIME))

  # If the Minecraft server screen is not running
  if ! screen -list | grep -q "minecraft"; then
    echo "Minecraft server has stopped early within $((ELAPSED_TIME / 3600)) hours."

    # Commit the server progress
    git add .
    git commit -m "Early server progress after $((ELAPSED_TIME / 3600)) hours"

    # Retry pushing the server progress until it succeeds
    while ! git push origin ${GIT_DEFAULT_BRANCH} -f; do
      echo "Git push failed, retrying in 10 seconds..."
      sleep 10
    done

    echo "Early server progress successfully pushed to GitHub."
    break
  fi

  # Check if time limit has passed
  if [ $ELAPSED_TIME -ge $TIME_LIMIT ]; then
    echo "Shutting down server after time limit exceeded, ${TIME_LIMIT} seconds passed."

    # If the server is still running, stop it
    if screen -list | grep -q "minecraft"; then
      screen -S minecraft -p 0 -X stuff "stop$(printf \\r)"

      # Wait for the server to stop
      while screen -list | grep -q "minecraft"; do
        echo "Waiting for Minecraft server to stop..."
        sleep 5
      done

      echo "Minecraft server has been stopped after time limit exceeded."

      # Commit and push the final server progress
      git add .
      git commit -m "Server progress after time limit exceeded."

      # Retry pushing the server progress until it succeeds
      while ! git push origin ${GIT_DEFAULT_BRANCH} -f; do
        echo "Git push failed, retrying in 10 seconds..."
        sleep 10
      done

      echo "Server progress after time limit exceeded successfully pushed to GitHub."
    fi

    break
  fi

  # Sleep for timeout seconds minutes before checking again
  sleep ${CHECK_TIMEOUT_SECONDS}
done
