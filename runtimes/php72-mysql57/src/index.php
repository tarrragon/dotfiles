<?php
// Parity probe：印出 runtime 的關鍵維度，跟 prod 的 phpinfo() 逐項比對。
// 每一行都是一個 parity 維度——版本、時區、擴充、DB 版本、sql_mode。
header('Content-Type: text/plain; charset=utf-8');

echo "PHP version : " . PHP_VERSION . "\n";
echo "timezone    : " . date_default_timezone_get() . "\n";
echo "memory_limit: " . ini_get('memory_limit') . "\n";
echo "extensions  : " . implode(', ', get_loaded_extensions()) . "\n\n";

try {
    $pdo = new PDO('mysql:host=db;dbname=app', 'root', 'secret');
    echo "MySQL ver   : " . $pdo->query('SELECT VERSION()')->fetchColumn() . "\n";
    echo "sql_mode    : " . $pdo->query('SELECT @@sql_mode')->fetchColumn() . "\n";
    echo "db timezone : " . $pdo->query('SELECT @@session.time_zone')->fetchColumn() . "\n";
} catch (PDOException $e) {
    echo "DB error    : " . $e->getMessage() . "\n";
}
