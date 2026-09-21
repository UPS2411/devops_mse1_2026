#!/bin/bash
# Rendered by Terraform templatefile(): ${bucket_name} and ${aws_region} are filled in.

# Update packages
dnf update -y



# Install Nginx and PHP-FPM (AWS CLI is preinstalled on Amazon Linux 2023)
dnf install -y nginx php php-fpm

# Remove default Nginx page and config
rm -f /usr/share/nginx/html/index.html
rm -f /etc/nginx/conf.d/default.conf

# Create index.php
cat > /usr/share/nginx/html/index.php <<'PHP'
<!DOCTYPE html>
<html>

<head>
    <title>Text Storage</title>

    <style>
        body {
            font-family: Arial, sans-serif;
            background: #f2f2f2;
            margin: 0;
            padding: 50px;
        }

        .container {
            max-width: 700px;
            margin: auto;
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }

        h1 {
            text-align: center;
        }

        textarea {
            width: 100%;
            height: 200px;
            padding: 12px;
            box-sizing: border-box;
            font-size: 16px;
            resize: vertical;
        }

        button {
            margin-top: 15px;
            padding: 12px 25px;
            background: #222;
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 16px;
        }

        button:hover {
            background: #444;
        }
    </style>
</head>

<body>

    <div class="container">

        <h1>Save Text to S3</h1>

        <form method="POST" action="/save.php">

            <textarea
                name="text"
                placeholder="Enter your text here..."
                required></textarea>

            <br>

            <button type="submit">
                Save to S3
            </button>

        </form>

    </div>

</body>
</html>
PHP

# Create save.php
cat > /usr/share/nginx/html/save.php <<'PHP'
<?php

if ($_SERVER["REQUEST_METHOD"] !== "POST") {
    header("Location: /");
    exit;
}

$text = $_POST["text"] ?? "";

if (trim($text) === "") {
    http_response_code(400);
    die("Text cannot be empty.");
}

$bucket = "${bucket_name}";
$region = "${aws_region}";

$filename = "text-" . time() . "-" . bin2hex(random_bytes(4)) . ".txt";
$tempFile = "/tmp/" . $filename;

file_put_contents($tempFile, $text);

$command =
    "aws s3 cp " .
    escapeshellarg($tempFile) . " " .
    escapeshellarg("s3://" . $bucket . "/" . $filename) .
    " --region " . escapeshellarg($region) .
    " 2>&1";

exec($command, $output, $returnCode);

unlink($tempFile);

if ($returnCode === 0) {

    $safeName = htmlspecialchars($filename);

    echo "
    <!DOCTYPE html>
    <html>

    <head>
        <title>Success</title>

        <style>
            body {
                font-family: Arial, sans-serif;
                background: #f2f2f2;
                padding: 50px;
                text-align: center;
            }

            .box {
                background: white;
                padding: 30px;
                max-width: 600px;
                margin: auto;
                border-radius: 10px;
            }

            a {
                display: inline-block;
                margin-top: 20px;
            }
        </style>
    </head>

    <body>

        <div class='box'>

            <h1>Text Saved Successfully!</h1>

            <p>File created:</p>

            <strong>$safeName</strong>

            <br>

            <a href='/'>
                Save another text
            </a>

        </div>

    </body>

    </html>
    ";

} else {

    http_response_code(500);

    echo "
    <h1>Error saving file</h1>
    <p>AWS CLI returned an error.</p>
    ";

    echo "<pre>";
    echo htmlspecialchars(implode("\n", $output));
    echo "</pre>";
}

?>
PHP

# Configure Nginx
cat > /etc/nginx/conf.d/text-storage.conf <<'NGINX'
server {
    listen 80;
    server_name _;

    root /usr/share/nginx/html;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include /etc/nginx/default.d/php.conf;
        fastcgi_pass unix:/run/php-fpm/www.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
NGINX

chown -R nginx:nginx /usr/share/nginx/html

# Validate config, then enable and start services
nginx -t

systemctl enable php-fpm nginx
systemctl restart php-fpm
systemctl restart nginx
