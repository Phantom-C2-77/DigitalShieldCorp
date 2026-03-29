<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Admin — Digital Shield</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:'Segoe UI',sans-serif;background:#0a1628;color:#c8d6e5;padding:40px}
h2{color:#00b4d8;margin-bottom:20px}
.card{background:#111d32;border:1px solid #1a2d4a;border-radius:10px;padding:24px;margin-bottom:16px}
.card h3{color:#00b4d8;margin-bottom:12px;font-size:15px}
input[type=file]{margin:8px 0}
.btn{padding:10px 20px;background:#00b4d8;color:#0a1628;border:none;border-radius:6px;font-weight:600;cursor:pointer}
.msg{padding:10px;border-radius:6px;margin:10px 0;font-size:13px}
.ok{background:rgba(16,185,129,.15);color:#10b981;border:1px solid rgba(16,185,129,.3)}
.err{background:rgba(239,68,68,.15);color:#ef4444;border:1px solid rgba(239,68,68,.3)}
a{color:#00b4d8}
pre{background:#0a0e1a;padding:12px;border-radius:6px;font-size:12px;margin-top:8px;overflow-x:auto}
</style>
</head>
<body>
<h2>🛡️ Admin Panel</h2>

<?php
// ──── VULN: File Upload with weak extension filtering ────
// Only blocks .exe and .bat — PHP, ASPX, JSP, etc. are allowed
$msg = '';
$msgClass = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['report'])) {
    $file = $_FILES['report'];
    $ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));

    // "Security" filter — only blocks obvious executables (easily bypassed)
    $blocked = ['exe', 'bat', 'cmd', 'com', 'scr'];

    if (in_array($ext, $blocked)) {
        $msg = "Blocked: executable files not allowed";
        $msgClass = 'err';
    } elseif ($file['size'] > 10 * 1024 * 1024) {
        $msg = "File too large (max 10MB)";
        $msgClass = 'err';
    } else {
        $uploadDir = '/var/www/html/assets/uploads/';
        $targetPath = $uploadDir . basename($file['name']);
        if (move_uploaded_file($file['tmp_name'], $targetPath)) {
            $msg = "Uploaded: <a href='/assets/uploads/" . htmlspecialchars($file['name']) . "'>/assets/uploads/" . htmlspecialchars($file['name']) . "</a>";
            $msgClass = 'ok';
        } else {
            $msg = "Upload failed";
            $msgClass = 'err';
        }
    }
}
?>

<div class="card">
<h3>📤 Upload Client Report</h3>
<p style="color:#5a6f8a;font-size:12px;margin-bottom:10px">Upload assessment reports for client review</p>
<?php if ($msg): ?><div class="msg <?= $msgClass ?>"><?= $msg ?></div><?php endif; ?>
<form method="POST" enctype="multipart/form-data">
<input type="file" name="report" required>
<br><button type="submit" class="btn">Upload</button>
</form>
</div>

<div class="card">
<h3>📂 Uploaded Files</h3>
<?php
$dir = '/var/www/html/assets/uploads/';
$files = array_diff(scandir($dir), ['.', '..', '.htaccess']);
if (empty($files)) {
    echo '<p style="color:#5a6f8a">No files uploaded</p>';
} else {
    echo '<ul style="list-style:none;padding:0">';
    foreach ($files as $f) {
        $size = filesize($dir . $f);
        echo "<li style='padding:4px 0;border-bottom:1px solid #1a2d4a'>";
        echo "<a href='/assets/uploads/$f'>$f</a>";
        echo " <span style='color:#5a6f8a;font-size:11px'>(" . number_format($size) . " bytes)</span>";
        echo "</li>";
    }
    echo '</ul>';
}
?>
</div>

<div class="card">
<h3>🔍 Server Info</h3>
<pre><?php
echo "PHP: " . phpversion() . "\n";
echo "Server: " . $_SERVER['SERVER_SOFTWARE'] . "\n";
echo "Document Root: " . $_SERVER['DOCUMENT_ROOT'] . "\n";
echo "User: " . get_current_user() . "\n";
echo "OS: " . php_uname() . "\n";
?></pre>
</div>

<p style="margin-top:20px"><a href="/">← Back to Portal</a></p>
</body>
</html>
