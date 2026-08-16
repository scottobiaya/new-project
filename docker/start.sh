echo "Creating start.sh..."
cat > /opt/scott-nginx/start.sh <<'EOF'
#!/bin/bash

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

nginx -g "daemon off;"
EOF

chmod +x /opt/scott-nginx/start.sh