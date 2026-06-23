const { spawn } = require('child_process');

console.log("Starting SSH tunnel via Pinggy...");
spawn('ssh', [
  '-t', '-t', // Force pseudo-terminal allocation
  '-o', 'StrictHostKeyChecking=no',
  '-o', 'UserKnownHostsFile=/dev/null',
  '-R', '80:localhost:3000',
  'a.pinggy.io',
  '-p', '443'
], { stdio: 'inherit' });
