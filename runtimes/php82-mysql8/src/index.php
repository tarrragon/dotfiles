<?php
// Parity probe（升級版）：跟 php72-mysql57 的 probe 一樣，用來跟舊版逐行對照差在哪。
header('Content-Type: text/plain; charset=utf-8');

echo "PHP version : " . PHP_VERSION . "\n";
echo "timezone    : " . date_default_timezone_get() . "\n";
echo "memory_limit: " . ini_get('memory_limit') . "\n";
echo "extensions  : " . implode(', ', get_loaded_extensions()) . "\n\n";

try {
    $pdo = new PDO('mysql:host=db;dbname=app', 'root', 'secret');
    echo "MySQL ver   : " . $pdo->query('SELECT VERSION()')->fetchColumn() . "\n";
    echo "sql_mode    : " . $pdo->query('SELECT @@sql_mode')->fetchColumn() . "\n";
    echo "auth plugin : " . $pdo->query("SELECT plugin FROM mysql.user WHERE user='root' LIMIT 1")->fetchColumn() . "\n";
    echo "db timezone : " . $pdo->query('SELECT @@session.time_zone')->fetchColumn() . "\n";
} catch (PDOException $e) {
    echo "DB error    : " . $e->getMessage() . "\n";
}
