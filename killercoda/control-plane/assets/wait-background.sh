#!/bin/bash
# Waits for the background installer to finish.
# Killercoda copies this to /usr/local/bin with +x via index.json assets.

echo "Setting up your environment — this takes about 1 minute..."
echo ""

spinner=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
i=0
while [ ! -f /tmp/.background-done ]; do
  printf "\r  %s Installing components..." "${spinner[$i]}"
  i=$(( (i + 1) % ${#spinner[@]} ))
  sleep 0.3
done
printf "\r  ✓ All components installed.         \n"

echo ""
echo "Environment is ready! Click 'Next' to continue."
