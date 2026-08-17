#!/bin/bash
set -e

echo "Creating web page..."

cat > /usr/share/nginx/html/index.html <<HTML
<!DOCTYPE html>
<html>
<head>
    <title>AWS EC2 Docker Server</title>
</head>
<body>
    <h1>AWS EC2 Linux Server</h1>
    <p>${SERVER_MESSAGE}</p>
</body>
</html>
HTML

echo "Starting Nginx..."

nginx -g "daemon off;" 