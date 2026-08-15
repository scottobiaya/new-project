#!/bin/bash

cat > /usr/share/nginx/html/index.html <<EOF
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
EOF

nginx -g "daemon off;"